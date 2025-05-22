extends Resource
class_name TweenCallback

var callDict : Dictionary = {
	"reduceHealth" : reduceHealth,
}

@export var callKey : String
@export var delay : float
@export var callableArguments : Array

func _init(
	callKey : String = "reduceHealth", 
	delay : float = 1.0, 
	callableArguments : Array = []) -> void:
	self.callKey = callKey
	self.delay = delay
	self.callableArguments = callableArguments
	

func reduceHealth(combatant: Combatant, damage: int):
	combatant.current_health -= damage
