extends Resource
class_name MiniProperties

enum Positions {Anchored, RelativeToPlayer}

@export var name : StringName
@export var posKey : Positions
@export var posArguments : Array
@export var shape : Shape2D
@export var spriteTexture : Texture2D
@export var damage : int

func _init(
	name : StringName = "",
	posKey : Positions = Positions.Anchored,
	posArguments : Array = [],
	shape : Shape2D = RectangleShape2D.new(),
	spriteTexture : Texture2D = PlaceholderTexture2D.new(),
	damage : int = 1
) -> void:
	self.name = name
	self.posKey = posKey
	self.posArguments = posArguments
	self.shape = shape
	self.spriteTexture = spriteTexture
	self.damage = damage
	
## Position Logic

## Position within the mini battle box, left = 0, top = 0 is top left corner
## and left = 1.0, top = 1.0 is bottom right corner
func Anchored(arenaUpperBounds : Vector2, left: float, top: float):
	# Assumed that topleft of arena will always be (0, 0)
	return Vector2(arenaUpperBounds.x * left, arenaUpperBounds.y * top)
	
func RelativeToPlayer(playerPosition : Vector2, distance : float, angle : float):
	return Vector2(
		playerPosition.x + distance * cos(deg_to_rad(angle)), 
		playerPosition.y + distance * sin(deg_to_rad(angle))
	)
