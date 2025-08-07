extends Node2D

## References
@onready var allies = $Field/Allies.get_children()
@onready var enemies = $Field/Enemies.get_children()
@onready var field = $Field
@onready var camera : Camera2D = $Field/BattleCamera
@onready var cameraFocus = $Field/BattleCamera/CenterFocus
@onready var reactorContainer : ReactionUI = $UILayer/BattleUI/Reactors
@onready var statUIs : HBoxContainer = $UILayer/BattleUI/StatUIs
@onready var targetStats = $UILayer/BattleUI/TargetStats
@onready var battleUI = $UILayer/BattleUI

## Load shader materials
@onready var selectShader = preload("res://assets/materials/allySelectedShader.tres")

## Scenes
@onready var selectionUI = preload("res://src/battle_engine/UI/SelectionUI.tscn")
@onready var characterStatusUI = preload("res://src/battle_engine/UI/CharacterStatusUI.tscn")
@onready var turnOrderUI = preload("res://src/battle_engine/UI/turnOrder.tscn")
@onready var miniBattleScene = preload("res://src/battle_engine/core/miniBattle/miniBattle.tscn")

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
var moveIndex : int = 0 ## The stage of the current move in execution
var selectedCombo : Combo ## The combo chain selected to be executed for the turn
var currentAction : Action ## The current action based on the comboIndex
var tweenCounter : int = 0 ## Track how many tweens have finished
var turnOrderNode: TurnOrderUI = null
var pendingTargetTween : Tween
var actingCombatantOnLeft : bool = true
var inputKeyD : InputEventKey
var inputKeyA : InputEventKey
var follower : QTE
var sizeSummation : int = 0
var inputLock : bool = false ## Lock player input until the next reaction is available (for timing reactions)
var miniBattle : MiniBattle = null

signal resetBattleCamera() ## Emits to battleCamera -> doCameraReset
signal resetSelectionUI() ## Emits to selectionUI -> resetUI
signal actionGaugeAdvance() ## Emits to Combatant -> actionGaugeAdvance
signal turnEndActionGauge() ## Emits to Combatant -> turnEndActionGauge
signal queueInputsForReaction(moves : Array[Move]) ## Emits to reactionPath -> addFollowers
signal targetUpdated(targets : Array) ## Emits to battleField -> targetUpdated
signal updateStatusUI(combatant : Combatant) ## Emits to characterStatusUI -> updateCharacter
signal toggleStatusUIVisibility(visibility : bool) ## Emits to characterStatusUI -> toggleVisibility
signal updateTurnOrder() ## Emits to turnOrder -> updateList
signal addTempTurnOrder(character: Combatant, actionValue: int) ## Emits to turnOrder -> addTemp
signal removeTempTurnOrder() ## Emits to turnOrder -> removeTemp
signal nextReaction() ## Emits to Combatant -> ...


## Custom lambda sorting function used to sort TurnOrder Objects by their speed fields
func _customSpeedSort(a : TurnOrder, b : TurnOrder):
		return (a.speed > b.speed)

func characterTurn(nextCombatant: Combatant):
	if actingCombatant != null:
		return
	updateTurnOrder.emit()
	if nextCombatant is Ally:
		actingCombatant = nextCombatant
		playerAction = true
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


## *Signal Function*
## Emits when overlappingCollisionArea "body_entered" signal is triggered in ally.gd (built-in node signal)
## @param body - The node which overlappingCollisionArea has an overlapping collision with
## @param damage - The number of hit points to remove from the colliding body's health
func _process_damage(body: Node2D, damage: int):
	body.current_health -= damage
	pass
	
# Applies a looping fade-in/fade-out animation to a node
func applyPendingSelectionTween(node : Node) -> Tween:
	var pendingSelectionTween = get_tree().create_tween()
	pendingSelectionTween.tween_property(node, "modulate:a", 0.5, 0.5)
	pendingSelectionTween.tween_property(node, "modulate:a", 1, 0.5)
	pendingSelectionTween.set_loops()
	return pendingSelectionTween

## *Signal Function*
## Emits when a selection is made from SelectionUI (Button press)
func readUIInputData(selectionChoice: String, listChoice: String) -> void:
	# Get the list of respective actions the acting combatant has available to them
	var list : Array
	if selectionChoice == "moves":
		list = actingCombatant.moves
	elif selectionChoice == "combos":
		list = actingCombatant.combos
	elif selectionChoice == "skills":
		list = actingCombatant.skills
		
	# Find the item the list with the matching name property of the player's choice
	var choice = list[
		list.find_custom(
			func(item): return item.name == listChoice
		)
	]
	
	# Initialize varibales based on action type
	if choice is Combo:
		selectedCombo = choice
	elif choice is Move:
		selectedCombo = Combo.new("move", [choice])
		
		
	
	## TODO: Temporary, change to dynamic selector based on history (last turn)
	selected = enemies[0]
	selected.find_child('Sprite2D').material = selectShader
	comboIndex = 0
	moveIndex = 0
	currentAction = selectedCombo.moveList[comboIndex].actionList[moveIndex]
	addTempTurnOrder.emit(actingCombatant, actingCombatant.defaultActionGauge/actingCombatant.speed)
	
	# Instatiate UI for enemy target stats
	# TODO: Change this, either just hide it or always show it
	var scene = characterStatusUI.instantiate()
	scene.set_script(CharacterStatusUI)
	var targetUI : CharacterStatusUI = scene
	targetStats.add_child(targetUI)
	targetUI.setCombatant(selected)
	targetUI.updateCharacter()
	if pendingTargetTween != null:
		pendingTargetTween.kill()
	pendingTargetTween = applyPendingSelectionTween(targetUI)

	actionState = "targetSelect"
	
## Processes enemy turn. Takes target and move selection from enemysignal
func processEnemyTurn(enemy : Enemy, targets : Array[Combatant], move : Move):
	print(enemy.name, " attacks ", targets[0].name)
	selectedCombo = Combo.new("move", [move])
	comboIndex = 0
	moveIndex = 0
	currentAction = selectedCombo.moveList[comboIndex].actionList[moveIndex]
	selectedTargets = targets
	#_process_damage(targets[0], move.comboList[0].damage)
	#prepareCombat()
	actionState = "StartMiniBattle"


## *Signal Function*
## Emit recieved from reactionPath.gd
func beginCombatExecutionState(timeSummation: float) -> void:
	actionState = "combatExecution"
	
## Transitions to the next action in the move/combo list
## @param followerIndex (int) : The index/order of the reactor object in the reaction UI list
func nextAction(followerIndex : int):
	var moveSize = selectedCombo.moveList.size()
	var actionSize = selectedCombo.moveList[comboIndex].actionList.size()

	moveIndex = followerIndex - sizeSummation

	# If a combo is currently being executed, this will trigger when a move reaches its end and updates
	# the combo indexing to the next move in the list
	if moveIndex >= actionSize and comboIndex < moveSize - 1:
		moveIndex = 0
		sizeSummation += actionSize
		comboIndex += 1
	
	# Go to next action in the current move's action list
	if moveIndex < actionSize:
		currentAction = selectedCombo.moveList[comboIndex].actionList[moveIndex]
	
	# Signal to the reaction UI for the next reaction event if not null
	if tweenCounter < followerIndex:
		nextReaction.emit()
	# Tracks the index of the previous reaction
	tweenCounter = followerIndex
	
## *Signal Function*
## Emit recieved from Tween.finished
func tweenEnds(tween : Tween, tweenOwner : Combatant, followerIndex : int) -> void:
	nextAction(followerIndex)
	inputLock = false
	tween.kill()
		
## *Signal Function*
## Emit recieved from reactionPath.gd
func endCombatExecutionState() -> void:
	actionState = "combatReset"
		
	
## Handles movement tweening
func handleMovementTween(primary : Combatant, secondary : Combatant, tweenProperties : Array[TweenProperty], followerIndex : int) -> void:
	if tweenProperties.is_empty():
		return
		
	var tween = get_tree().create_tween()
	tween.pause()
	tween.set_parallel(true)
		
	for tProp : TweenProperty in tweenProperties:
		# If a tween property should be ignored for combo fluidity, skip here
		if tProp.ID in selectedCombo.propertyDrops:
			continue
		
		var movementCall : Callable = tProp.calcDict[tProp.calcKey].bindv(tProp.calcArguments)
		var finalValue = movementCall.call(primary, secondary)
		tween.chain().tween_property(
			primary, 
			tProp.property, 
			finalValue,
			tProp.duration).set_trans(tProp.transition).set_delay(tProp.delay).set_ease(tProp.ease)
			
		for tCall : TweenCallback in tProp.callables:
			var effectCall : Callable = tCall.callDict[tCall.callKey]
			effectCall = effectCall.bindv([primary, secondary] + tCall.callableArguments)
			tween.tween_callback(effectCall).set_delay(tCall.delay)
			
	primary.tweenStartingPosition = primary.position
	tween.finished.connect(tweenEnds.bind(tween, primary, followerIndex))
	tween.play()
	
func handleCombatantAreaEntered(eneteringArea : Area2D, recievingArea : Area2D):
	var enteringNode = eneteringArea.get_parent()
	var recievingNode = recievingArea.get_parent()
	var action : Action = currentAction
	# If true, this is one of the targets of the attacker aka a reciever
	if enteringNode == actingCombatant and action.damageProcessing == action.Processes.Collision:	
		var attacker : Combatant = enteringNode
		var reciever : Combatant = recievingNode
		handleMovementTween(
			reciever, 
			attacker, 
			action.recieverAnimationProperties, 
			follower.getIndex())
	
## **RECIEVES SIGNAL from ReactionUI**
## Handles the user input during a quick-time combo string 
func processComboInput(correctInput : bool, reactionScore : float, fol : QTE):
	if inputLock:
		return
	inputLock = true
	follower = fol
	if (correctInput):
		print('yes')
		var action : Action = currentAction
		for reciever in selectedTargets:
			handleMovementTween(
				actingCombatant, 
				reciever, 
				action.attackerAnimationProperties, 
				follower.getIndex())
			# Handled by collision if collision based
			if action.damageProcessing == action.Processes.Timing:
				handleMovementTween(
					reciever, 
					actingCombatant, 
					action.recieverAnimationProperties, 
					follower.getIndex())
	else:
		print('wrung')
		var actionSize = selectedCombo.moveList[comboIndex].actionList.size()
		while follower.getIndex() - sizeSummation != actionSize:
			follower = reactorContainer.skipNextReaction()
			
		nextAction(follower.getIndex())
		
			
func ActionSelectState():
	## TODO: Change to signal. Only needs to happen once
	if actingCombatant is Enemy:
		actingCombatant._action()
	
func processTargetSelectChange(inputMapping: StringName):
	
	if inputMapping == "MoveDown":
		selectedList.pointer = selectedList.pointer.next
		while selectedList.pointer.data.targetted: # Skip characters already selected for targeting or acting
			selectedList.pointer = selectedList.pointer.next
	elif inputMapping == "MoveUp":
		selectedList.pointer = selectedList.pointer.prev
		while selectedList.pointer.data.targetted:
			selectedList.pointer = selectedList.pointer.prev
	else:
		selectedList = linkedAllies if selectedList == linkedEnemies else linkedEnemies

	if not selected.targetted:
		selected.find_child('Sprite2D').material = null
	selected = selectedList.pointer.data
	selected.find_child('Sprite2D').material = selectShader
	
	var hoveredEnemyStats = targetStats.get_child(-1)
	hoveredEnemyStats.setCombatant(selected)
	hoveredEnemyStats.updateCharacter()

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
	
	if Input.is_action_just_pressed("MoveDown"):
		processTargetSelectChange("MoveDown")

	elif Input.is_action_just_pressed("MoveUp"):
		processTargetSelectChange("MoveUp")
		
	elif Input.is_action_just_pressed("MoveLeft") or Input.is_action_just_pressed("MoveRight"):
		processTargetSelectChange("MoveHorizontal")
	
	if Input.is_action_just_pressed("Interact"):		
		selected.targetted = true
		selectedTargets.append(selected)
		
		if selectedTargets.size() == currentAction.maxTargets or combatants.size() - 1 == selectedTargets.size():
			targetStats.get_child(-1).modulate.a = 1.0
			pendingTargetTween.kill()
			# Initialize a bunch of stuff for future states
			prepareCombat()
		else:
			# Add another target UI
			var scene = characterStatusUI.instantiate()
			scene.set_script(CharacterStatusUI)
			var targetUI : CharacterStatusUI = scene
			targetStats.add_child(targetUI)
			targetUI.setCombatant(selected)
			targetUI.updateCharacter()
			if pendingTargetTween != null:
				##TODO: Fix this indexing this is stupid
				targetStats.get_child(-2).modulate.a = 1.0
				pendingTargetTween.kill()
			pendingTargetTween = applyPendingSelectionTween(targetUI)
			
func switchInputDirection():
	var xAvg = selectedTargets.reduce(func(accum, target): return accum + target.position.x, 0) / selectedTargets.size()
	if actingCombatant.position.x <= xAvg: #WAS on the RIGHT, now on the LEFT
		InputMap.action_erase_events("MoveTowards")
		InputMap.action_add_event("MoveTowards", inputKeyD)
		
		InputMap.action_erase_events("MoveAway")
		InputMap.action_add_event("MoveAway", inputKeyA)
		actingCombatantOnLeft = true
	elif actingCombatant.position.x > xAvg: # WAS on the LEFT, now on the RIGHT
		InputMap.action_erase_events("MoveTowards")
		InputMap.action_add_event("MoveTowards", inputKeyA)
		
		InputMap.action_erase_events("MoveAway")
		InputMap.action_add_event("MoveAway", inputKeyD)
		actingCombatantOnLeft = false
		
		
func CombatStartState():
	## TODO: move somewhere else so it's only calculated once
	var centroid = selectedTargets.reduce(func(accum, target): return accum + target.position, Vector2(0, 0)) / selectedTargets.size()
	if Vector2(
		centroid - actingCombatant.global_position
		).length() <= currentAction.minimumDistanceToTargets:
		actingCombatant.velocity = Vector2(0, 0)
		# Add inputs to reaction bar
		switchInputDirection()
		queueInputsForReaction.emit(selectedCombo.moveList)
		
func CombatExecutionState():
	## TODO: I really don't want this to run constantly so it needs to move eventually
	switchInputDirection()
	

func CombatResetState():
	if get_tree().get_processed_tweens().is_empty():
		actingCombatant.turnEndActionGauge()
		for combatant : Combatant in combatants:
			combatant.targetted = false
			combatant.global_position = combatant.baseBattlePosition
			combatant.velocity = Vector2(0, 0)
			combatant.following = null
		for ui : AllyStatusUI in statUIs.get_children():
			ui.updateCharacter()
		for ui : CharacterStatusUI in targetStats.get_children():
			targetStats.remove_child(ui)
			ui.queue_free()
		selectedCombo = null
		resetBattleCamera.emit()
		resetSelectionUI.emit()
		playerAction = false
		enemyAction = false
		actingCombatant = null
		selectedTargets = []
		tweenCounter = -1
		actionState = ""
		removeTempTurnOrder.emit()
		sizeSummation = 0

func StartMiniBattleState() -> void:
	self.add_child(miniBattle)
	miniBattle.initialize(actingCombatant.sequences[0], endMiniBattle)
	miniBattle.start()
	actionState = "PlayMiniBattle"
	

func PlayMiniBattleState() -> void:
	pass
	
func endMiniBattle() -> void:
	## TODO: Reset mini battle shit
	self.remove_child(miniBattle)
	camera.make_current()
	actionState = "combatReset"


func _ready():
	
	combatants = get_tree().get_nodes_in_group("Combatants")
	
	turnOrderNode = turnOrderUI.instantiate()
	battleUI.add_child(turnOrderNode)
	turnOrderNode.inputList(combatants)
	
	resetBattleCamera.connect(camera.doCameraReset)
	queueInputsForReaction.connect(reactorContainer.addFollowers)
	targetUpdated.connect(cameraFocus.updateTargetPoints)
	updateTurnOrder.connect(turnOrderNode.updateList)
	addTempTurnOrder.connect(turnOrderNode.addTemp)
	removeTempTurnOrder.connect(turnOrderNode.removeTemp)
	nextReaction.connect(reactorContainer.startNextReaction)
	
	inputKeyD = InputEventKey.new()
	inputKeyD.keycode = KEY_D
	
	inputKeyA = InputEventKey.new()
	inputKeyA.keycode = KEY_A
	
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
	for ally : Ally in allies:
		linkedAllies.append(ally)
		var scene = characterStatusUI.instantiate()
		scene.set_script(AllyStatusUI)
		var statUI : AllyStatusUI = scene
		statUIs.add_child(statUI)
		statUI.setCombatant(ally)
		statUI.updateCharacter()
	
	linkedEnemies = CircularDoubleLinkedList.new()
	for enemy : Enemy in enemies:
		linkedEnemies.append(enemy)
		
	selectedList = linkedEnemies
			
	for combatant : Combatant in combatants:
		actionGaugeAdvance.connect(combatant.actionAdvanceGauge)
		combatant.set_collision_mask_value(1, false)
		
	miniBattle = miniBattleScene.instantiate()
	
	
func _process(delta):
	
	if playerAction:
		match actionState:
			"actionSelect": ActionSelectState()
			"targetSelect": TargetSelectState()
			"combatStart": CombatStartState()
			"combatExecution": CombatExecutionState()
			"combatReset": CombatResetState()
	elif enemyAction:
		match actionState:
			"AISelect": ActionSelectState()
			"StartMiniBattle" : StartMiniBattleState()
			"PlayMiniBattle" : PlayMiniBattleState()
			"combatReset": CombatResetState()
	else:
		actionGaugeAdvance.emit()
