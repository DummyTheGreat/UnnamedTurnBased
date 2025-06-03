extends Resource
class_name TweenProperty

enum Funcs {None, EquationOfLine, KnockbackPrimaryByDistance}

var calcDict : Dictionary = {
	Funcs.None : None,
	Funcs.EquationOfLine : EquationOfLine,
	Funcs.KnockbackPrimaryByDistance : KnockbackPrimaryByDistance ##TODO: Rename
}

@export var ID : StringName
@export var property : String
@export var calcKey : Funcs
@export var calcArguments : Array
@export var duration : float
@export var delay : float
@export var transition : Tween.TransitionType
@export var ease : Tween.EaseType
@export var callables : Array[TweenCallback]


func _init(
	ID : StringName = "",
	property : String = "position",
	calcKey : Funcs = Funcs.None,
	calcArguments : Array = [],
	duration : float = 1.0,
	delay : float = 0.0,
	transition : Tween.TransitionType = Tween.TRANS_LINEAR,
	ease : Tween.EaseType = Tween.EASE_IN_OUT,
	callables : Array[TweenCallback] = []
	) -> void:
	self.ID = ID
	self.property = property
	self.calcKey = calcKey
	self.calcArguments = calcArguments
	self.duration = duration
	self.delay = delay
	self.transition = transition
	self.ease = ease
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
func KnockbackPrimaryByDistance(primary : Combatant, secondary : Combatant, distance : int, degreesAngle : int) -> Vector2:
	degreesAngle = degreesAngle % 360
	var primaryOnRight = primary.position.x > secondary.position.x
	var angledToRight = degreesAngle < 90 or degreesAngle > 270
	# Mirror angle along y-axis if primary on left/angle pointing right or primary on right/angle pointing left 
	if (!primaryOnRight and angledToRight) or (primaryOnRight and !angledToRight):
		degreesAngle = 180 - degreesAngle
	
	var diff = primary.position - secondary.position
	var unit = diff / diff.length()	
	var offset = unit.rotated(deg_to_rad(float(degreesAngle)) - unit.angle()) * distance
	# Invert y because negative is up for only god knows why
	offset.y *= -1
	print(offset)
	
	return primary.position + offset
	
	
