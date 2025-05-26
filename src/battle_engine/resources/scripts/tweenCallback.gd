extends Resource
class_name TweenCallback

enum Funcs {ReduceHealth, Sticky}

var callDict : Dictionary = {
	Funcs.ReduceHealth : reduceHealth,
	Funcs.Sticky : sticky
}

@export var callKey : Funcs
@export var delay : float
@export var callableArguments : Array

func _init(
	callKey : Funcs = Funcs.ReduceHealth, 
	delay : float = 0, 
	callableArguments : Array = []) -> void:
	self.callKey = callKey
	self.delay = delay
	self.callableArguments = callableArguments
	

func reduceHealth(primary : Combatant, secondary : Combatant, damage: int):
	primary.current_health -= damage
	
	
func sticky(primary : Combatant, secondary : Combatant, offset : int):
	var diff = primary.tweenStartingPosition - secondary.tweenStartingPosition
	var unit = diff / diff.length()	
	primary.attachToOther(secondary, unit * abs(offset))
