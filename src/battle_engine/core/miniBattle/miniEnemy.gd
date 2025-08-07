extends CharacterBody2D
class_name MiniEnemy

@onready var colShape : CollisionShape2D = $CollisionShape2D
@onready var sprite : Sprite2D = $Sprite2D

var playerTarget : MiniPlayer = null

var enemySpeed : int = 300
var initialJumpSpeed : int = -140
var moving : bool = false
var health : int = 20
var shape : Shape2D
var texture : Texture2D

func _ready() -> void:
	self.colShape.shape = shape
	self.sprite.texture = texture

func chasingAI():
	var dirVec = (playerTarget.position - self.position).normalized()
	self.velocity = dirVec * enemySpeed

func _process(delta: float) -> void:
	chasingAI()
	
func _physics_process(delta: float) -> void:
	
	move_and_slide()
	## Gravity
	#self.velocity.y += 20
