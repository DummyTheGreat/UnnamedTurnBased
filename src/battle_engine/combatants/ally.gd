class_name Ally
extends CharacterStats

## An Ally as any combatant that the player is able to take control of during battle

## References
@onready var directionRay = $RayCast2D
@onready var cameraFocus : CameraFocus = $"../../../BattleCamera/CenterFocus"
@onready var collisionShape = $CollisionShape2D

var isAttacking = false ## True if this ally is currently engaging in a combo or attack

var acceleration = 1 ## Animation movement acceleration

var collisionTarget = null ## Target being collided with in combat

var overlappingCollisionArea : Area2D = null ## 

## Emits on collision with another combatant
## Emission recieved by (battleField.gd)
signal target_updated()

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
		
	comboChains = [
		load("res://src/battle_engine/resources/combos/swordSlashDouble.tres"),
		load("res://src/battle_engine/resources/combos/sword_0_2.tres")
	]
		

func _action():
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# temporary until all allies have ray
	var collider = directionRay.get_collider() if directionRay != null else null
		
	if (collider != null and collider != collisionTarget):
		
		# Prevent endless loop into condition ^
		collisionTarget = collider
		
		# Find midpoint, create temporary node at midpoint for camera to focus on
		cameraFocus.first = self
		cameraFocus.second = collider
		
		target_updated.emit()
		
	speed = velocity.length()

	if speed > 0:
		velocity *= acceleration

	if speed < 0.01:
		velocity = Vector2(0, 0)
		acceleration = 1

	move_and_slide()
		
	for i in range(get_slide_collision_count() - 1):
		var collision = get_slide_collision(i)
		print(collision.get_collider())
