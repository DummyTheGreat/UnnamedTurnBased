extends MiniProperties
class_name ProjectileProperties

enum Directions {AtAngle, TowardsPlayer, TowardsPlayerRandom}

@export var speed : int
@export var dirKey : Directions
@export var dirArguments : Array

func _init(
	name : StringName = "",
	posKey : Positions = Positions.Anchored,
	posArguments : Array = [],
	shape : Shape2D = RectangleShape2D.new(),
	spriteTexture : Texture2D = PlaceholderTexture2D.new(),
	speed : int = 100,
	dirKey : Directions = Directions.AtAngle,
	dirArguments : Array = []
) -> void:
	super(name, posKey, posArguments, shape, spriteTexture)
	self.speed = speed
	self.dirKey = dirKey
	self.dirArguments = dirArguments


## Direction Logic

func AtAngle(angle : float) -> Vector2:
	return Vector2(1, 0).rotated(deg_to_rad(angle))
	
## It's assumed that position will be calculated first, as it is needed for direction
func TowardsPlayer(position : Vector2, playerPosition : Vector2) -> Vector2:
	return (playerPosition - position).normalized()
	
func TowardsPlayerRandom(position : Vector2, playerPosition : Vector2, angleDeviation : float) -> Vector2:
	return Vector2(0, 0)
