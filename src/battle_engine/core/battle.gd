extends Node2D

## References
@onready var allies = $Field/Allies.get_children()
@onready var enemies = $Field/Enemies.get_children()
@onready var field = $Field
@onready var camera = $BattleCamera
@onready var cameraFocus = $BattleCamera/CenterFocus
@onready var reactionPath = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath
@onready var reactionClickArea = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath/ClickArea
@onready var turnOrder = $UILayer/BattleUI/HorizontalContainer


## Load shaders
@onready var selectShader = preload("res://assets/shaders/allySelectedShader.tres")

## Scenes
@onready var selectionUI = preload("res://src/battle_engine/core/SelectionUI.tscn")
@onready var turnOrderUI = preload("res://src/battle_engine/core/turn-order.tscn")

var selectedAlly : Ally = null ## The ally combatant that the player is currently in control of
var actionState : String = "actionSelect" ## The state value for the battle's state machine
var selectedEnemy : Enemy = null ## The enemy which the player is targeting
var playerAction : bool = false ## True if it is the player's (ally's) turn, false if enemy's turn
var enemyAction : bool = false ## True if it is the enemy's (enemy's) turn
var comboIndex : int = 0 ## The stage of the current combo in execution
var selectedCombo : Combo ## The combo chain selected to be executed for the turn
var currentMove : CombatMove ## The current move based on the comboIndex
var returnPosition : Vector2 = Vector2(0, 0) ## The position which an ally or enemy returns after executing their turn
var actionType : String
var tweens : Array[Tween] ## A type of animation
var tweenCounter : int ## Track how many tweens have finished
var turnOrderNode: TurnOrderUI = null

signal resetBattleCamera() ## Emits to battleCamera -> doCameraReset
signal resetSelectionUI() ## Emits to selectionUI -> resetUI
signal actionGaugeAdvance() ## Emits to characterStats -> actionGaugeAdvance
signal turnEndActionGauge() ## Emits to characterStats -> turnEndActionGauge
signal queueInputsForReaction() ## Emits to reactionPath -> addFollowers
signal targetUpdated(targets : Array) ## Emits to battleField -> targetUpdated
signal updateTurnOrder() ## Emits to turnOrder -> updateList
signal addTempTurnOrder(character: CharacterStats, actionValue: int) ## Emits to turnOrder -> addTemp
signal removeTempTurnOrder() ## Emits to turnOrder -> removeTemp


## Custom lambda sorting function used to sort TurnOrder Objects by their speed fields
func _customSpeedSort(a : TurnOrder, b : TurnOrder):
		return (a.speed > b.speed)

func characterTurn(actingCharacter: CharacterStats):
	print(actingCharacter.name)
	print(actingCharacter.actionGauge)
	updateTurnOrder.emit()
	if actingCharacter is Ally:
		
		selectedAlly = actingCharacter
		playerAction = true
		selectedCombo = actingCharacter.comboChains[0]
		var uiInstance = selectionUI.instantiate()
		resetSelectionUI.connect(uiInstance.resetUI)
		selectedAlly.add_child(uiInstance)
		selectedAlly.find_child('Sprite2D').material = selectShader
	if actingCharacter is Enemy:
		selectedEnemy = actingCharacter
		enemyAction = true
	

## *Signal Function*
## Emits when overlappingCollisionArea "body_entered" signal is triggered in ally.gd (built-in node signal)
## @param body - The node which overlappingCollisionArea has an overlapping collision with
## @param damage - The number of hit points to remove from the colliding body's health
func _process_damage(body: Node2D, damage: int):
	body.current_health -= damage
	pass
	
## *Signal Function*
## Emits when a selection is made from SelectionUI (Button press)
func read_ui_input_data(selectionChoice: String, listChoice: String) -> void:
	var list : Array
	if selectionChoice == "moves":
		list = selectedAlly.moves
	elif selectionChoice == "combos":
		list = selectedAlly.comboChains
		
	var choice = list[
		list.find_custom(
			func(item): return item.name == listChoice
		)
	]
	if choice is Combo:
		actionType = "combo"
		selectedCombo = choice
	elif choice is CombatMove:
		actionType = "move"
		selectedCombo = Combo.new("move", [choice])
	
	## TODO: Temporary, change to dynamic selector based on history (last turn)
	selectedEnemy = enemies[0]
	selectedEnemy.find_child('Sprite2D').material = selectShader
	addTempTurnOrder.emit(selectedAlly, selectedAlly.defaultActionGauge/selectedAlly.speed)
	actionState = "targetSelect"


## *Signal Function*
## Emit recieved from reactionPath.gd
func beginCombatExecutionState(timeSummation: float) -> void:
	actionState = "combatExecution"
	
## *Signal Function*
## Emit recieved from Tween.finished
func tweenEnds() -> void:
	tweenCounter += 1
	
## *Signal Function*
## Emit recieved from reactionPath.gd
func endCombatExecutionState() -> void:
	actionState = "combatReset"
	

## Processes enemy turn. Takes target and move selection from enemy signal
func processEnemyTurn(enemy, target, move:CombatMove):
	print(enemy.name, " attacks ", target.name)
	_process_damage(target, move.damage)



	
## Handles movement tweening
func handleMovementTween(primary : CharacterStats, secondary : CharacterStats, tweenProperties : Array[TweenProperty], easeType : Tween.EaseType) -> void:
	if tweenProperties.is_empty():
		return
		
	var tween = get_tree().create_tween()
	tween.pause()
	tween.set_ease(easeType)
	for tProp in tweenProperties:
		
		var movementCall : Callable = tProp.calcDict[tProp.calcKey].bindv(tProp.calcArguments)
		var finalValue
		if movementCall.get_argument_count() == 2:
			finalValue = movementCall.call(primary, secondary)
		else:
			finalValue = movementCall.call(primary)
		tween.tween_property(
			primary, 
			tProp.property, 
			finalValue, 
			tProp.duration).set_trans(tProp.transition)
			
	tween.finished.connect(tweenEnds)		
	tweens.append(tween)
	
## Handles the user input during a quick-time combo string 
## @param attackVariant - The type of attack executed by the player determined by their input
## @param skillPointsUsed - The number of skill poitns to remove from the combatant
func processComboInput(attackVariant: String, skillPointsUsed: int):
	
	var queue = reactionClickArea.get_overlapping_areas()	
		
	if len(queue) > 0:
		
		#temp - get next move's distance boundary
		var nextMoveDistance : int
		if comboIndex + 1 < selectedCombo.comboList.size():
			nextMoveDistance = selectedCombo.comboList[comboIndex + 1].minimumDistanceToTargets
		
		if (attackVariant == queue[0].get_parent().attackVariant):
			var move : CombatMove = currentMove
			## NOTE: Temporary assignments, will need to be dynamically assigned
			var attacker = selectedAlly
			var reciever = selectedEnemy
			# Reduce skills points from gauge
			selectedAlly.skill_points -= skillPointsUsed

			handleMovementTween(attacker, reciever, move.attackerAnimationProperties, move.attackerAnimationEase)
			handleMovementTween(reciever, attacker, move.recieverAnimationProperties, move.recieverAnimationEase)
			
			# Run tweens
			for tween in tweens:
				tween.play()
			
			selectedAlly.isAttacking = true
			# Connect to the selected ally's signal for overlapping collision detection
			selectedAlly.overlappingCollisionArea.body_entered.connect(_process_damage.bind(move.damage))
			# Move to next move in list
			comboIndex += 1
			if comboIndex < selectedCombo.comboList.size():
				currentMove = selectedCombo.comboList[comboIndex]
		else:
			print("wrong!")
			
func ActionSelectState():
	##Pass and wait for signal
	pass
	
func processTargetSelectChange(inputMapping: String):
	var enemyIndex = selectedEnemy.get_index()
	var nextIndex: int
	if inputMapping == "move_down":
		nextIndex = enemyIndex + 1 if enemyIndex + 1 != enemies.size() else 0
	else:
		nextIndex = enemyIndex - 1 if enemyIndex != 0 else enemies.size() - 1
	
	selectedEnemy.find_child('Sprite2D').material = null
	selectedEnemy = enemies[nextIndex]
	selectedEnemy.find_child('Sprite2D').material = selectShader

	
func TargetSelectState():
	
	if Input.is_action_just_pressed("move_down"):
		processTargetSelectChange("move_down")

	elif Input.is_action_just_pressed("move_up"):
		processTargetSelectChange("move_up")
	
	if Input.is_action_just_pressed("interact"):
		# Initialize a bunch of stuff for future states
		var vel = Vector2(selectedEnemy.global_position - selectedAlly.global_position)
		var normalizedVelocity = vel / vel.length()
		returnPosition = selectedAlly.global_position
		selectedAlly.velocity = normalizedVelocity * 120
		selectedAlly.find_child('Sprite2D').material = null
		selectedEnemy.find_child('Sprite2D').material = null
		targetUpdated.emit([selectedAlly, selectedEnemy])
		comboIndex = 0
		currentMove = selectedCombo.comboList[comboIndex]
		
		actionState = "combatStart"
		
func CombatStartState():
	## TODO: 100 is completely arbitrary at the moment
	if Vector2(
		selectedEnemy.global_position - selectedAlly.global_position
		).length() <= currentMove.minimumDistanceToTargets:
		selectedAlly.velocity = Vector2(0, 0)
		# Add inputs to reaction bar
		#var timeSummation: float = 0
		queueInputsForReaction.emit(selectedCombo.comboList)
		
func CombatExecutionState():
	
	if Input.is_action_just_pressed("slash"):
		processComboInput("slash", 2)
		
	elif Input.is_action_just_pressed("strike"):
		processComboInput("strike", 4)

	elif Input.is_action_just_pressed("pierce"):
		processComboInput("pierce", 3)
		
func CombatResetState():
	if tweenCounter == tweens.size():
		for tw in tweens:
			tw.kill()
		selectedAlly.global_position = returnPosition
		selectedAlly.velocity = Vector2(0, 0)
		selectedAlly.turnEndActionGauge()
		selectedCombo = null
		resetBattleCamera.emit()
		resetSelectionUI.emit()
		playerAction = false
		selectedAlly = null
		actionState = "actionSelect"
		removeTempTurnOrder.emit()


func _ready():
	var combatants = get_tree().get_nodes_in_group("Combatants")
	
	resetBattleCamera.connect(camera.doCameraReset)
	queueInputsForReaction.connect(reactionPath.addFollowers)
	targetUpdated.connect(cameraFocus.updateTargetPoints)
	turnOrderNode = turnOrderUI.instantiate()
	turnOrder.add_child(turnOrderNode)
	turnOrderNode.inputList(combatants)
	turnOrder.move_child(turnOrderNode, 0)
	updateTurnOrder.connect(turnOrderNode.updateList)
	addTempTurnOrder.connect(turnOrderNode.addTemp)
	removeTempTurnOrder.connect(turnOrderNode.removeTemp)
	# populate allies and enemies groups here, temporarily static
	var cameraHeight : float = 108 * 2
	assert(allies.size() != 0)
	
	var spacing : float = cameraHeight / allies.size()
	for i in range(allies.size()):
		var pos = Vector2(-100 , spacing - spacing * i)
		allies[i].global_position = pos

	spacing = cameraHeight / enemies.size()
	for i in range(enemies.size()):
		var pos = Vector2(100, spacing / 2 - spacing * i)
		enemies[i].global_position = pos
		
	
	
	for combatant in combatants:
		actionGaugeAdvance.connect(combatant.actionAdvanceGauge)
				
					
			
func _process(delta):
	
	if playerAction:
		match actionState:
			"actionSelect": ActionSelectState()
			"targetSelect": TargetSelectState()
			"combatStart": CombatStartState()
			"combatExecution": CombatExecutionState()
			"combatReset": CombatResetState()
				
	elif enemyAction and !playerAction:
		# Enemy turn
		enemyAction = false
		# Enemy does its action
		selectedEnemy._action()
		selectedEnemy.turnEndActionGauge()
		pass
	else:
		actionGaugeAdvance.emit()
