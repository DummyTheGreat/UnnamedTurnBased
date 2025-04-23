extends Node2D

@onready var allies = $Field/Allies.get_children()
@onready var enemies = $Field/Enemies.get_children()
@onready var camera = $Camera2D
@onready var reactionPath = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath
@onready var reactionClickArea = $UILayer/BattleUI/HorizontalContainer/ReactionUI/ReactionPath/ClickArea
@onready var turnOrder = $UILayer/BattleUI/HorizontalContainer/MarginContainer/TurnOrderVisual

@onready var selectShader = preload("res://assets/shaders/allySelectedShader.tres")

var selectedAlly = null
var actionState = "actionSelect"
var selectedEnemy = null
var playerAction : bool = false
var comboIndex = 0

const weapons = {
	"sword": 0,
	"spear": 1,
	"hammer": 2
}

const attack = {
	0: "slash",
	1: "strike",
	2: "pierce"
}

var selectedComboChain = null

var speedMap : Array[TurnOrder] = []

var returnPosition : Vector2 = Vector2(0, 0)

func _customSpeedSort(a : TurnOrder, b : TurnOrder):
		if a.speed > b.speed:
			return true
		return false

func _process_damage(body: Node2D, damage: int):
	body.current_health -= damage
	pass

func getNextCombatant():
	
	var combatants = get_tree().get_nodes_in_group("Combatants")
	var nextCombatant = combatants[combatants.find_custom(
		func(combatant): return combatant.combatID == speedMap[0].id
		)]
	selectedComboChain = nextCombatant.comboChains[0]
	return nextCombatant
	
func processComboInput(attackVariant: int, skillPointsUsed: int):
	
	var overlaps = reactionClickArea.get_overlapping_areas()
		
	if len(overlaps) > 0:
		
		if (attack[attackVariant] == overlaps[0].get_parent().attackVariant):
			var currMove : CombatMove = selectedComboChain.comboList[comboIndex]
			selectedAlly.skill_points -= skillPointsUsed
			
			var vel = Vector2(selectedEnemy.global_position - selectedAlly.global_position)
			var normalizedVelocity = vel / vel.length()
			
			selectedAlly.velocity = normalizedVelocity * currMove.playerSpeed
			selectedAlly.acceleration = 0.99
			# Disable collision mask that matches the collision layer of the enemy target
			selectedAlly.collision_mask = 0b00
			selectedAlly.isAttacking = true
			# Connect to signal for overlapping collision detection
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
					var follower = ReactionPathFollower.new(attack[move.attackVariant], timeSummation)
					reactionPath.add_child(follower)
				
		
		if actionState == "combatExecution":
			
			# Can probably be optimized as a signal
			if len(reactionPath.get_children()) == 2:
				actionState = "combatReset"
					
			if Input.is_action_just_pressed("slash"):
				processComboInput(0, 2)
				
			elif Input.is_action_just_pressed("strike"):
				processComboInput(1, 4)

			elif Input.is_action_just_pressed("pierce"):
				processComboInput(2, 3)
				
		if actionState == "combatReset":
			selectedAlly.global_position = returnPosition
			
				
	else:
		# Enemy turn
		pass
