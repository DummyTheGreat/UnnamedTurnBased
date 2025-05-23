extends Resource
class_name TweenCallback

enum Funcs {ReduceHealth}

var callDict : Dictionary = {
	Funcs.ReduceHealth : reduceHealth,
}

@export var callKey : Funcs
@export var delay : float
@export var callableArguments : Array

func _init(
	callKey : Funcs = Funcs.ReduceHealth, 
	delay : float = 1.0, 
	callableArguments : Array = []) -> void:
	self.callKey = callKey
	self.delay = delay
	self.callableArguments = callableArguments
	

func reduceHealth(combatant: Combatant, damage: int):
	combatant.current_health -= damage
