extends CharacterBody2D
class_name Projectile

## Base, straight shooting projectile class
@onready var projectileShape : CollisionShape2D = $CollisionPolygon2D
@onready var sprite : Sprite2D = $Sprite2D
@onready var collider : Area2D = $Collider
@onready var colliderShape : CollisionShape2D = $Collider/CollisionShape2D

var speed : int = 200
var direction : Vector2 = Vector2(0, 0)
var damage : int = 4
var shape : Shape2D
var texture : Texture2D

## **SIGNAL FUNCTION**
## Triggered when body enters projectile/projectile enters a body
func assessCollision(body : Node2D):
	if body is MiniPlayer:
		body.health -= damage
	
	
func _ready() -> void:
	projectileShape.shape = shape
	colliderShape.shape = shape
	sprite.texture = texture
	sprite.scale = Vector2((shape.radius * 2) / texture.get_width(), (shape.radius * 2) / texture.get_height())
	collider.body_entered.connect(assessCollision)
	
	
func _physics_process(delta: float) -> void:
	self.velocity = direction * speed
	self.move_and_slide()
