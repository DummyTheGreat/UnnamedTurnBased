class_name Ally
extends CharacterStats

## An Ally as any combatant that the player is able to take control of during battle

## References
@onready var collisionShape = $CollisionShape2D

var movementSpd = 0 ##spd
var isAttacking = false ## True if this ally is currently engaging in a combo or attack

var acceleration = 1 ## Animation movement acceleration

var collisionTarget = null ## Target being collided with in combat

var overlappingCollisionArea : Area2D = null ## 

func _ready():

	super._ready()
	
	# Health Bar
	var healthBar = TextureProgressBar.new()
	healthBar.name = "HealthBar"
	
	var health_bar_green = Image.new()
	health_bar_green.load("res://assets/health_bar_green.png")
	var t2 = ImageTexture.create_from_image(health_bar_green)

	healthBar.texture_progress = t2
	healthBar.max_value = self.max_health
	healthBar.value = self.current_health
	healthBar.scale = Vector2(0.2, 0.2)
	healthBar.set_position(Vector2(-7, -14))
	self.add_child(healthBar)
	
	# Create an area equivalent to the size of the collision box for overlapping detections
	overlappingCollisionArea = Area2D.new()
	var areaCollision = CollisionShape2D.new()
	var rectShape = RectangleShape2D.new()
	
	rectShape.size = collisionShape.shape.size
	areaCollision.shape = rectShape
	
	# Add to tree
	self.add_child(overlappingCollisionArea)
	overlappingCollisionArea.add_child(areaCollision)
	
	self.moves = [
		load("res://src/battle_engine/resources/moves/sword_pierce.tres"),
		load("res://src/battle_engine/resources/moves/sword_slash.tres")
	]
	
	self.comboChains = [
		load("res://src/battle_engine/resources/combos/swordSlashDouble.tres"),
		load("res://src/battle_engine/resources/combos/sword_0_2.tres")
	]
			

func _action():
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		
	movementSpd = velocity.length()

	if movementSpd > 0:
		velocity *= acceleration
#
	if movementSpd < 0.01:
		velocity = Vector2(0, 0)
		acceleration = 1

	move_and_slide()
		
	for i in range(get_slide_collision_count() - 1):
		var collision = get_slide_collision(i)
		print(collision.get_collider())
