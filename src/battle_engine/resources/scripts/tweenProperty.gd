extends Resource
class_name TweenProperty

@export var property : String
@export var endPosition : Vector2
@export var duration : float
@export var transition : Tween.TransitionType

func _init(
	property = "position", 
	endPosition = Vector2(0, 0), 
	duration = 1.0,
	transition = Tween.TRANS_LINEAR
	) -> void:
	self.property = property
	self.endPosition = endPosition
	self.duration = duration
	self.transition = transition
