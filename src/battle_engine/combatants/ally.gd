class_name Ally
extends Combatant

## An Ally as any combatant that the player is able to take control of during battle

## References
@onready var collisionShape = $CollisionShape2D
#@onready var animationPlayer : AnimationPlayer = $AnimationPlayer

var movementSpd = 0 ##spd

var acceleration = 1 ## Animation movement acceleration

var collisionTarget = null ## Target being collided with in combat

var overlappingCollisionArea : Area2D = null ## 

var healthBar = null

func _ready():

	super._ready()

	self.moves = [
		load("res://src/battle_engine/resources/moves/sword_slash.tres"),
		load("res://src/battle_engine/resources/moves/sword_pierce.tres"),
		load("res://src/battle_engine/resources/moves/dual_shot.tres")
	]
	
	self.comboChains = [
		load("res://src/battle_engine/resources/combos/swordSlashDouble.tres"),
		load("res://src/battle_engine/resources/combos/sliceAndSkewer.tres")
	]
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_and_slide()
