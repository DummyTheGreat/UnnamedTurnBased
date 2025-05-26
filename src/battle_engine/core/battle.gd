extends Node2D

## References
@onready var allies = $Field/Allies.get_children()
@onready var enemies = $Field/Enemies.get_children()
@onready var field = $Field
@onready var camera = $BattleCamera
@onready var cameraFocus = $BattleCamera/CenterFocus
@onready var reactionPath = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath
@onready var reactionClickArea = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath/ClickArea
@onready var statUIs = $UILayer/BattleUI/StatUIs
@onready var targetStats = $UILayer/BattleUI/TargetStats
@onready var turnOrder = $UILayer/BattleUI/HorizontalContainer

## Load shader materials
@onready var selectShader = preload("res://assets/materials/allySelectedShader.tres")

## Scenes
@onready var selectionUI = preload("res://src/battle_engine/UI/SelectionUI.tscn")
@onready var characterStatusUI = preload("res://src/battle_engine/UI/CharacterStatusUI.tscn")
@onready var turnOrderUI = preload("res://src/battle_engine/UI/turnOrder.tscn")

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
var pendingTargetTween : Tween
var actingCombatantOnLeft : bool = true
var inputKeyD : InputEventKey
var inputKeyA : InputEventKey

signal resetBattleCamera() ## Emits to battleCamera -> doCameraReset
signal resetSelectionUI() ## Emits to selectionUI -> resetUI
signal actionGaugeAdvance() ## Emits to Combatant -> actionGaugeAdvance
signal turnEndActionGauge() ## Emits to Combatant -> turnEndActionGauge
signal queueInputsForReaction() ## Emits to reactionPath -> addFollowers
signal targetUpdated(targets : Array) ## Emits to battleField -> targetUpdated
signal updateStatusUI(combatant : Combatant) ## Emits to characterStatusUI -> updateCharacter
signal toggleStatusUIVisibility(visibility : bool) ## Emits to characterStatusUI -> toggleVisibility
signal updateTurnOrder() ## Emits to turnOrder -> updateList
signal addTempTurnOrder(character: Combatant, actionValue: int) ## Emits to turnOrder -> addTemp
signal removeTempTurnOrder() ## Emits to turnOrder -> removeTemp


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


## *Signal Function*
## Emits when overlappingCollisionArea "body_entered" signal is triggered in ally.gd (built-in node signal)
## @param body - The node which overlappingCollisionArea has an overlapping collision with
## @param damage - The number of hit points to remove from the colliding body's health
func _process_damage(body: Node2D, damage: int):
	body.current_health -= damage
	pass
	
func applyPendingSelectionTween(node : Node) -> Tween:
	var pendingSelectionTween = get_tree().create_tween()
	pendingSelectionTween.tween_property(node, "modulate:a", 0.5, 0.5)
	pendingSelectionTween.tween_property(node, "modulate:a", 1, 0.5)
	pendingSelectionTween.set_loops()
	return pendingSelectionTween	

## *Signal Function*
## Emits when a selection is made from SelectionUI (Button press)
func readUIInputData(selectionChoice: String, listChoice: String) -> void:
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
	addTempTurnOrder.emit(actingCombatant, actingCombatant.defaultActionGauge/actingCombatant.speed)
	
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
func tweenEnds(index : int, tweenOwner : Combatant) -> void:
	if tweenOwner == actingCombatant:
		comboIndex += 1
		if comboIndex < selectedCombo.comboList.size():
			currentMove = selectedCombo.comboList[comboIndex]
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
	for tProp : TweenProperty in tweenProperties:
		
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
			tProp.duration).set_trans(tProp.transition).set_delay(tProp.delay)
			
		for tCall : TweenCallback in tProp.callables:
			var effectCall : Callable = tCall.callDict[tCall.callKey]
			effectCall = effectCall.bindv([primary, secondary] + tCall.callableArguments)
			tween.tween_callback(effectCall).set_delay(tCall.delay)
			
	primary.tweenStartingPosition = primary.position
	tween.finished.connect(tweenEnds.bind(tweens.size(), primary))
	tweens.append(tween)
	tween.play()
	
func handleCombatantAreaEntered(eneteringArea : Area2D, recievingArea : Area2D):
	var enteringNode = eneteringArea.get_parent()
	var recievingNode = recievingArea.get_parent()
	var move : CombatMove = currentMove
	# If true, this is one of the targets of the attacker aka a reciever
	if enteringNode == actingCombatant and move.damageProcessing == move.Processes.Collision:	
		var attacker : Combatant = enteringNode
		var reciever : Combatant = recievingNode
		handleMovementTween(reciever, attacker, move.recieverAnimationProperties, move.recieverAnimationEase)
	
## Handles the user input during a quick-time combo string 
## @param attackVariant - The type of attack executed by the player determined by their input
## @param skillPointsUsed - The number of skill poitns to remove from the combatant
func processComboInput(inputKeyName : StringName, skillPointsUsed : int):
	
	var queue = reactionClickArea.get_overlapping_areas()	
	if len(queue) > 0:
		var follower : ReactionPathFollower = queue[0].get_parent()
		#
		#var nextMoveDistance : int
		#if comboIndex + 1 < selectedCombo.comboList.size():
			#nextMoveDistance = selectedCombo.comboList[comboIndex + 1].minimumDistanceToTargets
		print("FOLLOWER INPUT KEY", follower.inputKeyName)
		if (inputKeyName == follower.inputKeyName):
			var move : CombatMove = currentMove
			## NOTE: Temporary assignments, will need to be dynamically assigned
			var attacker = actingCombatant
			# Reduce skills points from gauge
			actingCombatant.skill_points -= skillPointsUsed

			for reciever in selectedTargets:
				handleMovementTween(attacker, reciever, move.attackerAnimationProperties, move.attackerAnimationEase)
				# Handled by collision if collision based
				if move.damageProcessing == move.Processes.Timing:
					handleMovementTween(reciever, attacker, move.recieverAnimationProperties, move.recieverAnimationEase)
			
			# Disable for reaction
			queue[0].set_collision_layer_value(2, false)
			queue[0].set_collision_mask_value(2, false)
		else:
			print("wrong!")
			
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
		
		if selectedTargets.size() == currentMove.maxTargets or combatants.size() - 1 == selectedTargets.size():
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
		
func CombatStartState():
	## TODO: move somewhere else so it's only calculated once
	var centroid = selectedTargets.reduce(func(accum, target): return accum + target.position, Vector2(0, 0)) / selectedTargets.size()
	if Vector2(
		centroid - actingCombatant.global_position
		).length() <= currentMove.minimumDistanceToTargets:
		actingCombatant.velocity = Vector2(0, 0)
		# Add inputs to reaction bar
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
		print(InputMap.action_has_event("MoveTowards", inputKeyA))
		print(InputMap.action_has_event("MoveTowards", inputKeyD))
		queueInputsForReaction.emit(selectedCombo.comboList)
		
func CombatExecutionState():
	## TODO: I really don't want this to run constantly so it needs to move eventually
	var xAvg = selectedTargets.reduce(func(accum, target): return accum + target.position.x, 0) / selectedTargets.size()
	if !actingCombatantOnLeft and actingCombatant.position.x <= xAvg: #WAS on the RIGHT, now on the LEFT
		InputMap.action_add_event("MoveTowards", inputKeyD)
		InputMap.action_erase_event("MoveTowards", inputKeyA)
		
		InputMap.action_add_event("MoveAway", inputKeyA)
		InputMap.action_erase_event("MoveAway", inputKeyD)
		actingCombatantOnLeft = true
	elif actingCombatantOnLeft and actingCombatant.position.x > xAvg: # WAS on the LEFT, now on the RIGHT
		InputMap.action_add_event("MoveTowards", inputKeyA)
		InputMap.action_erase_event("MoveTowards", inputKeyD)
		
		InputMap.action_add_event("MoveAway", inputKeyD)
		InputMap.action_erase_event("MoveAway", inputKeyA)
		actingCombatantOnLeft = false
	
	if Input.is_action_just_pressed("SlashAction"):
		processComboInput("SlashAction", 2)
		
	elif Input.is_action_just_pressed("PierceAction"):
		processComboInput("PierceAction", 4)

	elif Input.is_action_just_pressed("StrikeAction"):
		processComboInput("StrikeAction", 3)
		
	elif Input.is_action_just_pressed("MoveTowards"):
		processComboInput("MoveTowards", 0)
	
	elif Input.is_action_just_pressed("MoveAway"):
		processComboInput("MoveAway", 0)

func CombatResetState():
	if tweenCounter == tweens.size():
		for tw in tweens:
			tw.kill()
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
		tweens = []
		tweenCounter = 0
		actionState = ""
		removeTempTurnOrder.emit()

func _ready():
	
	combatants = get_tree().get_nodes_in_group("Combatants")
	
	turnOrderNode = turnOrderUI.instantiate()
	turnOrder.add_child(turnOrderNode)
	turnOrderNode.inputList(combatants)
	turnOrder.move_child(turnOrderNode, 0)
	
	resetBattleCamera.connect(camera.doCameraReset)
	queueInputsForReaction.connect(reactionPath.addFollowers)
	targetUpdated.connect(cameraFocus.updateTargetPoints)
	updateTurnOrder.connect(turnOrderNode.updateList)
	addTempTurnOrder.connect(turnOrderNode.addTemp)
	removeTempTurnOrder.connect(turnOrderNode.removeTemp)
	
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
			"combatStart": CombatStartState()
			"combatExecution": CombatExecutionState()
			"combatReset": CombatResetState()
	else:
		actionGaugeAdvance.emit()
