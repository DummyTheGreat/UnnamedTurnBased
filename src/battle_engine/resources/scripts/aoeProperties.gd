extends MiniProperties
class_name AOEProperties

@export var warningTime : float
@export var effectTime : float
@export var animationList : Array[StringName]

func _init(
	name : StringName = "",
	posKey : Positions = Positions.Anchored,
	posArguments : Array = [],
	shape : Shape2D = RectangleShape2D.new(),
	spriteTexture : Texture2D = PlaceholderTexture2D.new(),
	warningTime : float = 1.0,
	effectTime : float = 1.0,
	animationList : Array[StringName] = []
) -> void:
	super(name, posKey, posArguments, shape, spriteTexture)
	self.warningTime = warningTime
	self.effectTime = effectTime
	self.animationList = animationList
