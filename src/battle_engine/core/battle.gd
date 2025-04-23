extends Node2D

## References
@onready var allies = $Field/Allies.get_children()
@onready var enemies = $Field/Enemies.get_children()
@onready var camera = $BattleCamera
@onready var reactionPath = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath
@onready var reactionClickArea = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath/ClickArea
@onready var turnOrder = $UILayer/BattleUI/HorizontalContainer/MarginContainer/TurnOrderVisual

## Load shaders
@onready var selectShader = preload("res://assets/shaders/allySelectedShader.tres")

var selectedAlly = null ## The ally combatant that the player is currently in control of
var actionState = "actionSelect" ## The state value for the battle's state machine
var selectedEnemy = null ## The enemy which the player is targeting
var playerAction : bool = false ## True if it is the player's (ally's) turn, false if enemy's turn
var comboIndex = 0 ## The stage of the current combo in execution
var selectedComboChain = null ## The combo chain selected to be executed for the turn
var speedMap : Array[TurnOrder] = [] ## The list for tracking the current order of combatant turns
var returnPosition : Vector2 = Vector2(0, 0) ## The position which an ally or enemy returns after executing their turn

## Custom lambda sorting function used to sort TurnOrder Objects by their speed fields
func _customSpeedSort(a : TurnOrder, b : TurnOrder):
		return (a.speed > b.speed)

## *Signal Function*
## Emits when overlappingCollisionArea "body_entered" signal is triggered in ally.gd (built-in node signal)
## @param body - The node which overlappingCollisionArea has an overlapping collision with
## @param damage - The number of hit points to remove from the colliding body's health
func _process_damage(body: Node2D, damage: int):
	body.current_health -= damage
	pass

## Gets a list of the combatants in the battle field and determines the next one to take turn
## @return - A reference to the node of the next combatant to take turn
func getNextCombatant():
	
	var combatants = get_tree().get_nodes_in_group("Combatants")
	var nextCombatant = combatants[combatants.find_custom(
		func(combatant): return combatant.combatID == speedMap[0].id
		)]
	# TODO: Temporary, will need to be changed so that the player can select a combo
	selectedComboChain = nextCombatant.comboChains[0]
	return nextCombatant
	
## Handles the user input during a quick-time combo string 
## @param attackVariant - The type of attack executed by the player determined by their input
## @param skillPointsUsed - The number of skill poitns to remove from the combatant
func processComboInput(attackVariant: String, skillPointsUsed: int):
	
	var overlaps = reactionClickArea.get_overlapping_areas()
		
	if len(overlaps) > 0:
		
		if (attackVariant == overlaps[0].get_parent().attackVariant):
			var currMove : CombatMove = selectedComboChain.comboList[comboIndex]
			selectedAlly.skill_points -= skillPointsUsed
			
			var vel = Vector2(selectedEnemy.global_position - selectedAlly.global_position)
			var normalizedVelocity = vel / vel.length()
			
			selectedAlly.velocity = normalizedVelocity * currMove.playerSpeed
			selectedAlly.acceleration = 0.99
			# Disable collision mask that matches the collision layer of the enemy target
			selectedAlly.collision_mask = 0b00
			selectedAlly.isAttacking = true
			# Connect to the selected ally's signal for overlapping collision detection
			selectedAlly.overlappingCollisionArea.body_entered.connect(_process_damage.bind(currMove.damage))
			comboIndex += 1
		else:
			print("wrong!")


func _ready():
	
	# populate allies and enemies groups here, temporarily static
	var cameraHeight : float = 108 * 2
	assert(allies.size() != 0)

	var spacing : float = cameraHeight / allies.size()
	for i in range(allies.size()):
		var pos = Vector2(-100, spacing - spacing * i)
		allies[i].translate(pos)

	spacing = cameraHeight / enemies.size()
	for i in range(enemies.size()):
		var pos = Vector2(100, spacing / 2 - spacing * i)
		enemies[i].translate(pos)
		
	var combatants = get_tree().get_nodes_in_group("Combatants")
				
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
		var combatantName = combatants[combatants.find_custom(
			func(combatant): return combatant.combatID == entry.id
			)].characterName
		labelChild.text = str(combatantName)
		turnOrder.add_child(labelChild)
		
	var nextCombatant = getNextCombatant()
	if nextCombatant is Ally:
		playerAction = true
		selectedAlly = nextCombatant
		selectedAlly.find_child('Sprite2D').material = selectShader
	else:
		playerAction = false
		selectedEnemy = nextCombatant
		
			
			
func _process(delta):
	
	if playerAction:
	
		if Input.is_action_just_pressed("interact"):
			match actionState:
				"actionSelect":
					selectedEnemy = enemies[0] # Temporary, change to dynamic selector based on history
					selectedEnemy.find_child('Sprite2D').material = selectShader
					actionState = "targetSelect"
				"targetSelect":
					actionState = "combatStart"
					
		if actionState == "targetSelect":
			var enemyIndex = selectedEnemy.get_index()
			var nextIndex = enemyIndex
			
			if Input.is_action_just_pressed("move_down"):
				nextIndex = enemyIndex + 1 if enemyIndex + 1 != enemies.size() else 0
			elif Input.is_action_just_pressed("move_up"):
				nextIndex = enemyIndex - 1 if enemyIndex != 0 else enemies.size() - 1

			selectedEnemy.find_child('Sprite2D').material = null
			selectedEnemy = enemies[nextIndex]
			selectedEnemy.find_child('Sprite2D').material = selectShader
			
		if actionState == "combatStart":
			
			var vel = Vector2(selectedEnemy.global_position - selectedAlly.global_position)
			var normalizedVelocity = vel / vel.length()
			returnPosition = selectedAlly.global_position
			selectedAlly.velocity = normalizedVelocity * 120
			selectedAlly.find_child('RayCast2D').target_position = vel
			actionState = "combatMovement"
			
		if actionState == "combatMovement":
			var vel = Vector2(selectedEnemy.global_position - selectedAlly.global_position)
			if vel.length() <= 100:
				selectedAlly.velocity = Vector2(0, 0)
				comboIndex = 0
				actionState = "combatExecution"
				# Add inputs to reaction bar
				var timeSummation: float = 0
				print(selectedComboChain.comboList[0])
				for move in selectedComboChain.comboList:
					timeSummation += move.reactionTime
					var follower = ReactionPathFollower.new(move.attackVariant, timeSummation)
					reactionPath.add_child(follower)
				
		
		if actionState == "combatExecution":
			
			# Can probably be optimized as a signal
			if len(reactionPath.get_children()) == 2:
				actionState = "combatReset"
					
			if Input.is_action_just_pressed("slash"):
				processComboInput("slash", 2)
				
			elif Input.is_action_just_pressed("strike"):
				processComboInput("strike", 4)

			elif Input.is_action_just_pressed("pierce"):
				processComboInput("pierce", 3)
				
		if actionState == "combatReset":
			selectedAlly.global_position = returnPosition
			
				
	else:
		# Enemy turn
		pass
