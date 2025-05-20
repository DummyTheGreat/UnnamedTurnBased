extends Node2D

## References
@onready var allies = $Field/Allies.get_children()
@onready var enemies = $Field/Enemies.get_children()
@onready var field = $Field
@onready var camera = $BattleCamera
@onready var cameraFocus = $BattleCamera/CenterFocus
@onready var reactionPath = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath
@onready var reactionClickArea = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath/ClickArea
@onready var turnOrder = $UILayer/BattleUI/HorizontalContainer/MarginContainer/TurnOrderVisual
@onready var battleUI = $UILayer/BattleUI

## Load shaders
@onready var selectShader = preload("res://assets/shaders/allySelectedShader.tres")

## Scenes
@onready var selectionUI = preload("res://src/battle_engine/core/SelectionUI.tscn")
@onready var characterStatusUI = preload("res://src/battle_engine/UI/CharacterStatusUI.tscn")

var combatants : Array[Node] ## List of all combatants
var actingCombatant : CharacterStats = null ## The ally combatant that the player is currently in control of
var actionState : String = "actionSelect" ## The state value for the battle's state machine
var selectedTargets : Array[CharacterStats] = [] ## A list of targets to execute the action on
var linkedAllies : CircularDoubleLinkedList
var linkedEnemies : CircularDoubleLinkedList
var selectedList : CircularDoubleLinkedList
var selected : CharacterStats = null
var playerAction : bool = false ## True if it is the player's (ally's) turn, false if enemy's turn
var enemyAction : bool = false ## True if it is the enemy's (enemy's) turn
var comboIndex : int = 0 ## The stage of the current combo in execution
var selectedCombo : Combo ## The combo chain selected to be executed for the turn
var currentMove : CombatMove ## The current move based on the comboIndex
var speedMap : Array[TurnOrder] = [] ## The list for tracking the current order of combatant turns
var returnPosition : Vector2 = Vector2(0, 0) ## The position which an ally or enemy returns after executing their turn
var actionType : String
var tweens : Array[Tween] ## A type of animation
var tweenCounter : int ## Track how many tweens have finished

signal resetBattleCamera() ## Emits to battleCamera -> doCameraReset
signal resetSelectionUI() ## Emits to selectionUI -> resetUI
signal actionGaugeAdvance() ## Emits to characterStats -> actionGaugeAdvance
signal turnEndActionGauge() ## Emits to characterStats -> turnEndActionGauge
signal queueInputsForReaction() ## Emits to reactionPath -> addFollowers
signal targetUpdated(targets : Array) ## Emits to battleField -> targetUpdated



## Custom lambda sorting function used to sort TurnOrder Objects by their speed fields
func _customSpeedSort(a : TurnOrder, b : TurnOrder):
		return (a.speed > b.speed)

func characterTurn(actingCharacter: CharacterStats):
	if actingCharacter is Ally:
		actingCombatant = actingCharacter
		playerAction = true
		selectedCombo = actingCharacter.comboChains[0]
	if actingCharacter is Enemy:
		actingCombatant = actingCharacter
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
		list = actingCombatant.moves
	elif selectionChoice == "combos":
		list = actingCombatant.comboChains
		
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
	selected = enemies[0]
	selected.find_child('Sprite2D').material = selectShader
	comboIndex = 0
	currentMove = selectedCombo.comboList[comboIndex]
	actionState = "targetSelect"
	
## Processes enemy turn. Takes target and move selection from enemy signal
func processEnemyTurn(enemy, target, move:CombatMove):
	print(enemy.name, " attacks ", target.name)
	_process_damage(target, move.damage)
	


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
	


## Gets a list of the combatants in the battle field and determines the next one to take turn
## @return - A reference to the node of the next combatant to take turn
func getNextCombatant():
	
	var combatants = get_tree().get_nodes_in_group("Combatants")
	var nextCombatant = combatants[
		combatants.find_custom(
			func(combatant): return combatant.combatID == speedMap[0].id
		)
	]
	return nextCombatant
	
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
			var attacker = actingCombatant
			# Reduce skills points from gauge
			actingCombatant.skill_points -= skillPointsUsed

			for reciever in selectedTargets:
				handleMovementTween(attacker, reciever, move.attackerAnimationProperties, move.attackerAnimationEase)
				handleMovementTween(reciever, attacker, move.recieverAnimationProperties, move.recieverAnimationEase)
			
			# Run tweens
			for tween in tweens:
				tween.play()
			
			actingCombatant.isAttacking = true
			# Connect to the selected ally's signal for overlapping collision detection
			actingCombatant.overlappingCollisionArea.body_entered.connect(_process_damage.bind(move.damage))
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
	
	
	if inputMapping == "move_down":
		selectedList.pointer = selectedList.pointer.next
		while selectedList.pointer.data.targetted: # Skip characters already selected for targeting or acting
			selectedList.pointer = selectedList.pointer.next
	elif inputMapping == "move_up":
		selectedList.pointer = selectedList.pointer.prev
		while selectedList.pointer.data.targetted:
			selectedList.pointer.pointer = selectedList.pointer.prev
	else:
		selectedList = linkedAllies if selectedList == linkedEnemies else linkedEnemies

	if not selected.targetted:
		selected.find_child('Sprite2D').material = null
	selected = selectedList.pointer.data
	selected.find_child('Sprite2D').material = selectShader

	
func TargetSelectState():
	
	if Input.is_action_just_pressed("move_down"):
		processTargetSelectChange("move_down")

	elif Input.is_action_just_pressed("move_up"):
		processTargetSelectChange("move_up")
		
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		processTargetSelectChange("move_horizontal")
	
	if Input.is_action_just_pressed("interact"):
		
		selected.targetted = true
		selectedTargets.append(selected)
		
		if selectedTargets.size() == currentMove.maxTargets or combatants.size() - 1 == selectedTargets.size():
			# Initialize a bunch of stuff for future states
			var centroid = selectedTargets.reduce(func(accum, target): return accum + target.position, Vector2(0, 0)) / selectedTargets.size()
			var vel = Vector2(centroid - actingCombatant.global_position)
			var normalizedVelocity = vel / vel.length()
			returnPosition = actingCombatant.global_position
			actingCombatant.velocity = normalizedVelocity * 120
			actingCombatant.find_child('Sprite2D').material = null
			for target in selectedTargets:
				target.find_child('Sprite2D').material = null
			targetUpdated.emit([actingCombatant] + selectedTargets)
			actionState = "combatStart"
		
func CombatStartState():
	## TODO: move somewhere else so it's only calculated once
	var centroid = selectedTargets.reduce(func(accum, target): return accum + target.position, Vector2(0, 0)) / selectedTargets.size()
	if Vector2(
		centroid - actingCombatant.global_position
		).length() <= currentMove.minimumDistanceToTargets:
		actingCombatant.velocity = Vector2(0, 0)
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
		actingCombatant.global_position = returnPosition
		actingCombatant.velocity = Vector2(0, 0)
		actingCombatant.turnEndActionGauge()
		for combatant : CharacterStats in combatants:
			combatant.targetted = false
		selectedCombo = null
		resetBattleCamera.emit()
		resetSelectionUI.emit()
		actionState = "actionSelect"


func _ready():
	
	resetBattleCamera.connect(camera.doCameraReset)
	queueInputsForReaction.connect(reactionPath.addFollowers)
	targetUpdated.connect(cameraFocus.updateTargetPoints)
	
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
		
	combatants = get_tree().get_nodes_in_group("Combatants")
	
	linkedAllies = CircularDoubleLinkedList.new()
	for ally in allies:
		linkedAllies.append(ally)
	
	linkedEnemies = CircularDoubleLinkedList.new()
	for enemy in enemies:
		linkedEnemies.append(enemy)
		
	selectedList = linkedEnemies
	
	var statUI : CharacterStatusUI = characterStatusUI.instantiate()
	battleUI.add_child(statUI)
		
	for combatant : CharacterStats in combatants:
		actionGaugeAdvance.connect(combatant.actionAdvanceGauge)
		combatant.characterTurn.connect(statUI.updateCharacter)
				
	# TODO: Chnage this to use the Combatants group
	# Set initial turn order
	for i in range(allies.size() + enemies.size()):
		if i < allies.size():
			speedMap.append(TurnOrder.new(allies[i].speed, allies[i].combatID))
		else:
			i -= allies.size()
			speedMap.append(TurnOrder.new(enemies[i].speed, enemies[i].combatID))
		
	speedMap.sort_custom(_customSpeedSort)
	
	# Populate turn order UI
	for entry in speedMap:
		var labelChild = Label.new()
		var combatant = combatants[combatants.find_custom(
			func(combatant): return combatant.combatID == entry.id
			)]
		labelChild.text = str(combatant.characterName) + str(combatant.actionValue)
		
		turnOrder.add_child(labelChild)
		
	var nextCombatant = getNextCombatant()
	if nextCombatant is Ally:
		playerAction = true
		actingCombatant = nextCombatant
		
		var uiInstance = selectionUI.instantiate()
		resetSelectionUI.connect(uiInstance.resetUI)
		actingCombatant.add_child(uiInstance)
		actingCombatant.find_child('Sprite2D').material = selectShader
	else:
		playerAction = false
		actingCombatant = nextCombatant
					
			
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
		if Input.is_action_just_pressed("move_left"):
			enemyAction = false
			# print(selectedEnemy.name + " moved")
			# Enemy does its action
			actingCombatant._action()
			actingCombatant.turnEndActionGauge()
			pass
	else:
		actionGaugeAdvance.emit()
