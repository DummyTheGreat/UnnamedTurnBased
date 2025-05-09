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

## Load shaders
@onready var selectShader = preload("res://assets/shaders/allySelectedShader.tres")

## Scenes
@onready var selectionUI = preload("res://src/battle_engine/core/SelectionUI.tscn")

var selectedAlly : Ally = null ## The ally combatant that the player is currently in control of
var actionState : String = "actionSelect" ## The state value for the battle's state machine
var selectedEnemy : Enemy = null ## The enemy which the player is targeting
var playerAction : bool = false ## True if it is the player's (ally's) turn, false if enemy's turn
var enemyAction : bool = false ## True if it is the enemy's (enemy's) turn
var comboIndex : int = 0 ## The stage of the current combo in execution
var selectedCombo : Combo ## The combo chain selected to be executed for the turn
var currentMove : CombatMove ## The current move based on the comboIndex
var speedMap : Array[TurnOrder] = [] ## The list for tracking the current order of combatant turns
var returnPosition : Vector2 = Vector2(0, 0) ## The position which an ally or enemy returns after executing their turn
var actionType : String
var tweens : Array[Tween] ## A type of animation

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
		selectedAlly = actingCharacter
		playerAction = true
		selectedCombo = actingCharacter.comboChains[0]
	if actingCharacter is Enemy:
		selectedEnemy = actingCharacter
		enemyAction = true
	
	print(actingCharacter.name)

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
	actionState = "targetSelect"


## *Signal Function*
## Emit recieved from reactionPath.gd
func beginCombatExecutionState(timeSummation: float) -> void:
	actionState = "combatExecution"
	
## *Signal Function*
## Emit recieved from reactionPath.gd
func endCombatExecutionState() -> void:
	actionState = "combatReset"


## Processes enemy turn. Takes target and move selection from enemy signal
func processEnemyTurn(enemy, target, move:CombatMove):
	print(enemy.name, " attacks ", target.name)
	_process_damage(target, move.damage)


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
			var currMove : CombatMove = currentMove
			selectedAlly.skill_points -= skillPointsUsed
			# Directional vector of ally and enemy positions
			var dirVec = Vector2(selectedAlly.position - selectedEnemy.position)
			# Find endPos by vector equation of the direction line by scalar t
			var t : float = 2.0
			var endPos = Vector2(
				selectedAlly.position.x + t * (selectedEnemy.position.x - selectedAlly.position.x),
				selectedAlly.position.y + t * (selectedEnemy.position.y - selectedAlly.position.y)
			)
			# I'm gonna tweeeen
			var allyTween = get_tree().create_tween()
			allyTween.set_ease(Tween.EASE_OUT)
			allyTween.tween_property(selectedAlly, "position", endPos, 1).set_trans(Tween.TRANS_EXPO)
			tweens.append(allyTween)
			
			var prevPos = selectedEnemy.position
			var knockbackPos = Vector2(
				selectedEnemy.position.x, selectedEnemy.position.y - 50
			)

			var enemyTween = get_tree().create_tween()
			enemyTween.set_ease(Tween.EASE_OUT)
			enemyTween.tween_property(selectedEnemy, "position", knockbackPos, 0.5).set_trans(Tween.TRANS_SINE)
			enemyTween.tween_property(selectedEnemy, "position", prevPos, 0.5).set_trans(Tween.TRANS_BOUNCE)
			tweens.append(enemyTween)
			
			selectedAlly.isAttacking = true
			# Connect to the selected ally's signal for overlapping collision detection
			selectedAlly.overlappingCollisionArea.body_entered.connect(_process_damage.bind(currMove.damage))
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
	for tw in tweens:
		tw.kill()
	selectedAlly.global_position = returnPosition
	selectedAlly.velocity = Vector2(0, 0)
	selectedAlly.turnEndActionGauge()
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
		
	var combatants = get_tree().get_nodes_in_group("Combatants")
	
	for combatant in combatants:
		actionGaugeAdvance.connect(combatant.actionAdvanceGauge)
				
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
		selectedAlly = nextCombatant
		
		var uiInstance = selectionUI.instantiate()
		resetSelectionUI.connect(uiInstance.resetUI)
		selectedAlly.add_child(uiInstance)
		selectedAlly.find_child('Sprite2D').material = selectShader
	else:
		playerAction = false
		selectedEnemy = nextCombatant
					
			
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
			selectedEnemy._action()
			selectedEnemy.turnEndActionGauge()
			pass
	else:
		actionGaugeAdvance.emit()
