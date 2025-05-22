extends Node2D

## References
@onready var allies = $Field/Allies.get_children()
@onready var enemies = $Field/Enemies.get_children()
@onready var field = $Field
@onready var camera = $BattleCamera
@onready var cameraFocus = $BattleCamera/CenterFocus
@onready var reactionPath = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath
@onready var reactionClickArea = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath/ClickArea
@onready var battleUI = $UILayer/BattleUI
@onready var turnOrder = $UILayer/BattleUI/HorizontalContainer

## Load shaders
@onready var selectShader = preload("res://assets/shaders/allySelectedShader.tres")

## Scenes
@onready var selectionUI = preload("res://src/battle_engine/UI/SelectionUI.tscn")
@onready var characterStatusUI = preload("res://src/battle_engine/UI/CharacterStatusUI.tscn")
@onready var turnOrderUI = preload("res://src/battle_engine/UI/turn-order.tscn")

var combatants : Array[Node] ## List of all combatants
var actingCombatant : Combatant = null ## The ally combatant that the player is currently in control of
var actionState : String = "actionSelect" ## The state value for the battle's state machine
var selectedTargets : Array[Combatant] = [] ## A list of targets to execute the action on
var linkedAllies : CircularDoubleLinkedList
var linkedEnemies : CircularDoubleLinkedList
var selectedList : CircularDoubleLinkedList
var selected : Combatant = null
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
signal actionGaugeAdvance() ## Emits to Combatant -> actionGaugeAdvance
signal turnEndActionGauge() ## Emits to Combatant -> turnEndActionGauge
signal queueInputsForReaction() ## Emits to reactionPath -> addFollowers
signal targetUpdated(targets : Array) ## Emits to battleField -> targetUpdated
signal updateStatusUI(combatant : Combatant) ## Emits to characterStatusUI -> updateCharacter
signal toggleStatusUIVisibility(visibility : bool) ## Emits to characterStatusUI -> toggleVisibility


## Custom lambda sorting function used to sort TurnOrder Objects by their speed fields
func _customSpeedSort(a : TurnOrder, b : TurnOrder):
		return (a.speed > b.speed)

func characterTurn(nextCombatant: Combatant):
	if actingCombatant != null:
		return
		
	if nextCombatant is Ally:
		actingCombatant = nextCombatant
		playerAction = true
		selectedCombo = actingCombatant.comboChains[0]
		var uiInstance = selectionUI.instantiate()
		resetSelectionUI.connect(uiInstance.resetUI)
		actingCombatant.add_child(uiInstance)
		actingCombatant.find_child('Sprite2D').material = selectShader
		toggleStatusUIVisibility.emit(true)
		actionState = "actionSelect"
		
	if nextCombatant is Enemy:
		actingCombatant = nextCombatant
		enemyAction = true
		actionState = "AISelect"
	
	updateStatusUI.emit(actingCombatant)
	

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
func processEnemyTurn(enemy : Enemy, targets : Array[Combatant], move : Combo):
	print(enemy.name, " attacks ", targets[0].name)
	selectedCombo = move
	comboIndex = 0
	currentMove = selectedCombo.comboList[comboIndex]
	selectedTargets = targets
	#_process_damage(targets[0], move.comboList[0].damage)
	prepareCombat()


## *Signal Function*
## Emit recieved from reactionPath.gd
func beginCombatExecutionState(timeSummation: float) -> void:
	actionState = "combatExecution"
	
## *Signal Function*
## Emit recieved from Tween.finished
func tweenEnds(index : int) -> void:
	tweenCounter += 1
	
## *Signal Function*
## Emit recieved from reactionPath.gd
func endCombatExecutionState() -> void:
	actionState = "combatReset"
	
	
## Handles movement tweening
func handleMovementTween(primary : Combatant, secondary : Combatant, tweenProperties : Array[TweenProperty], easeType : Tween.EaseType) -> void:
	if tweenProperties.is_empty():
		return
		
	var tween = get_tree().create_tween()
	tween.pause()
	tween.set_parallel(true)
	tween.set_ease(easeType)
	for tProp in tweenProperties:
		
		var movementCall : Callable = tProp.calcDict[tProp.calcKey].bindv(tProp.calcArguments)
		var finalValue
		if movementCall.get_argument_count() == 2:
			finalValue = movementCall.call(primary, secondary)
		else:
			finalValue = movementCall.call(primary)
		tween.chain().tween_property(
			primary, 
			tProp.property, 
			finalValue, 
			tProp.duration).set_trans(tProp.transition)
			
		if tProp.parallelCallable != null:
			var tCall : TweenCallback = tProp.parallelCallable
			var effectCall : Callable = tCall.callDict[tCall.callKey]
			effectCall = effectCall.bindv([secondary] + tCall.callableArguments)
			tween.tween_callback(effectCall).set_delay(tCall.delay)
			
	tween.finished.connect(tweenEnds.bind(tweens.size()))
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
			
			comboIndex += 1
			if comboIndex < selectedCombo.comboList.size():
				currentMove = selectedCombo.comboList[comboIndex]
		else:
			print("wrong!")
			
func ActionSelectState():
	## TODO: Change to signal. Only needs to happen once
	if actingCombatant is Enemy:
		actingCombatant._action()
	
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

func prepareCombat():
	var centroid = selectedTargets.reduce(func(accum, target): return accum + target.position, Vector2(0, 0)) / selectedTargets.size()
	var vel = Vector2(centroid - actingCombatant.global_position)
	var normalizedVelocity = vel / vel.length()
	## TODO: Change arbitrary 120 to dynamically scale with the camera or some shit
	actingCombatant.velocity = normalizedVelocity * 120
	actingCombatant.find_child('Sprite2D').material = null
	for target in selectedTargets:
		target.find_child('Sprite2D').material = null
	targetUpdated.emit([actingCombatant] + selectedTargets)
	toggleStatusUIVisibility.emit(false)
	actionState = "combatStart"
	
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
			prepareCombat()
		
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
		actingCombatant.turnEndActionGauge()
		for combatant : Combatant in combatants:
			combatant.targetted = false
			combatant.global_position = combatant.baseBattlePosition
			combatant.velocity = Vector2(0, 0)
		selectedCombo = null
		resetBattleCamera.emit()
		resetSelectionUI.emit()
		playerAction = false
		enemyAction = false
		actingCombatant = null
		selectedTargets = []
		tweens = []
		tweenCounter = 0
		actionState = ""


func _ready():
	combatants = get_tree().get_nodes_in_group("Combatants")
	
	var statUI : CharacterStatusUI = characterStatusUI.instantiate()
	battleUI.add_child(statUI)
	
	updateStatusUI.connect(statUI.updateCharacter)
	toggleStatusUIVisibility.connect(statUI.toggleVisibility)
	resetBattleCamera.connect(camera.doCameraReset)
	queueInputsForReaction.connect(reactionPath.addFollowers)
	targetUpdated.connect(cameraFocus.updateTargetPoints)
	turnOrderNode = turnOrderUI.instantiate()
	turnOrder.add_child(turnOrderNode)
	turnOrderNode.inputList(combatants)
	#get rid of later
	turnOrder.move_child(turnOrderNode, 0)
	
	
	# populate allies and enemies groups here, temporarily static
	var cameraHeight : float = 108 * 2
	assert(allies.size() != 0)
	
	var spacing : float = cameraHeight / allies.size()
	for i in range(allies.size()):
		var pos = Vector2(-100 , spacing - spacing * i)
		allies[i].baseBattlePosition = pos
		allies[i].global_position = pos

	spacing = cameraHeight / enemies.size()
	for i in range(enemies.size()):
		var pos = Vector2(100, spacing / 2 - spacing * i)
		enemies[i].baseBattlePosition = pos
		enemies[i].global_position = pos
	
	linkedAllies = CircularDoubleLinkedList.new()
	for ally in allies:
		linkedAllies.append(ally)
	
	linkedEnemies = CircularDoubleLinkedList.new()
	for enemy in enemies:
		linkedEnemies.append(enemy)
		
	selectedList = linkedEnemies
		
	for combatant : Combatant in combatants:
		actionGaugeAdvance.connect(combatant.actionAdvanceGauge)
		combatant.set_collision_mask_value(1, false)
					
			
func _process(delta):
	
	if playerAction:
		turnOrderNode.updateList()
		match actionState:
			"actionSelect": ActionSelectState()
			"targetSelect": TargetSelectState()
			"combatStart": CombatStartState()
			"combatExecution": CombatExecutionState()
			"combatReset": CombatResetState()
				
	elif enemyAction:
		match actionState:
			"AISelect": ActionSelectState()
			"combatStart": CombatStartState()
			"combatExecution": CombatExecutionState()
			"combatReset": CombatResetState()
	else:
		actionGaugeAdvance.emit()
