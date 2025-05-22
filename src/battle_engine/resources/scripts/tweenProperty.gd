extends Resource
class_name TweenProperty

var calcDict : Dictionary = {
	"EquationOfLine" : EquationOfLine,
	"ShiftRecieverByDistance" : ShiftRecieverByDistance
}

@export var property : String
@export var calcKey : String
@export var calcArguments : Array
@export var duration : float
@export var transition : Tween.TransitionType
@export var parallelCallable : TweenCallback


func _init(
	property = "position",
	calcKey = "EquationOfLine",
	calcArguments = [],
	duration = 1.0,
	transition = Tween.TRANS_LINEAR,
	parallelCallable = null
	) -> void:
	self.property = property
	self.calcKey = calcKey
	self.calcArguments = calcArguments
	self.duration = duration
	self.transition = transition
	self.parallelCallable = parallelCallable
	

## Finds a position relative the the line formed by two vectors
func EquationOfLine(attacker : Combatant, reciever : Combatant, scale : float) -> Vector2:
	return Vector2(
		attacker.position.x + scale * (reciever.position.x - attacker.position.x),
		attacker.position.y + scale * (reciever.position.y - attacker.position.y)
	)
	
## Knockback
func ShiftRecieverByDistance(reciever : Combatant, distance : Vector2) -> Vector2:
	return reciever.position + distance
	
