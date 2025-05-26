extends Resource
class_name TweenProperty

enum Funcs {None, EquationOfLine, ShiftRecieverByDistance}

var calcDict : Dictionary = {
	Funcs.None : None,
	Funcs.EquationOfLine : EquationOfLine,
	Funcs.ShiftRecieverByDistance : ShiftRecieverByDistance
}

@export var property : String
@export var calcKey : Funcs
@export var calcArguments : Array
@export var duration : float
@export var delay : float
@export var transition : Tween.TransitionType
@export var callables : Array[TweenCallback]


func _init(
	property : String = "position",
	calcKey : Funcs = Funcs.None,
	calcArguments : Array = [],
	duration : float = 1.0,
	delay : float = 0.0,
	transition : Tween.TransitionType = Tween.TRANS_LINEAR,
	callables : Array[TweenCallback] = []
	) -> void:
	self.property = property
	self.calcKey = calcKey
	self.calcArguments = calcArguments
	self.duration = duration
	self.delay = delay
	self.transition = transition
	self.callables = callables
	

func None(primary : Combatant, secondary : Combatant):
	return primary.position

## Finds a position relative the the line formed by two vectors
func EquationOfLine(primary : Combatant, secondary : Combatant, scale : float) -> Vector2:
	return Vector2(
		primary.position.x + scale * (secondary.position.x - primary.position.x),
		primary.position.y + scale * (secondary.position.y - primary.position.y)
	)
	
## Knockback
func ShiftRecieverByDistance(secondary : Combatant, distance : Vector2) -> Vector2:
	return secondary.position + distance
	
	
