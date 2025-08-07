extends CharacterBody2D
class_name MiniPlayer

@onready var camera : Camera2D = $MiniCamera

@export var playerSpeed : int = 400

var initialJumpSpeed : int = -140
var moving : bool = false
var health : int = 20

var releasedJump : bool = false

func _ready() -> void:
	pass
	
func _input(event: InputEvent) -> void:
	pass
	
func toggleCamera():
	self.camera.enabled = !self.camera.enabled
	if not self.camera.is_current():
		self.camera.make_current()
	
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("MoveRight") and Input.is_action_pressed("MoveLeft"):
		self.velocity.x = 0
	elif Input.is_action_pressed("MoveRight"):
		self.velocity.x = playerSpeed
	elif Input.is_action_pressed("MoveLeft"):
		self.velocity.x = -1 * playerSpeed
	elif self.velocity.x != 0:
		self.velocity.x *= 0.9
		if abs(self.velocity.x) < 1:
			self.velocity.x = 0
	
	if Input.is_action_just_released("MoveUp"):
		releasedJump = true
	if Input.is_action_just_pressed("MoveUp") and not releasedJump:
		self.velocity.y += initialJumpSpeed
		
	
	move_and_slide()
		
	if not self.is_on_floor():
		if Input.is_action_pressed("MoveUp") and not releasedJump:
			initialJumpSpeed *= 0.8
			self.velocity.y += initialJumpSpeed + 20 # Gravity rounded
		else:
			self.velocity.y += 20
	else:
		initialJumpSpeed = -140
		releasedJump = false
		self.velocity.y = 0
	
	#var col = get_last_slide_collision()
	#print(col)
