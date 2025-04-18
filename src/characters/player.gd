extends CharacterStats


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
# var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _process(delta):
	self.velocity = Vector2.ZERO
	
	var left = Input.is_action_pressed("move_left")
	var right = Input.is_action_pressed("move_right")
	var up = Input.is_action_pressed("move_up")
	var down = Input.is_action_pressed("move_down")
	
	if left:
		self.velocity.x -= SPEED
	elif right:
		self.velocity.x += SPEED
		
	if up:
		self.velocity.y -= SPEED
	elif down:
		self.velocity.y += SPEED

	move_and_slide()
