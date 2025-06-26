extends Resource
class_name TweenCallback

enum Funcs {ChangeHealth, Sticky}

var callDict : Dictionary = {
	Funcs.ChangeHealth : changeHealth,
	Funcs.Sticky : sticky
}

@export var callKey : Funcs
@export var delay : float
@export var callableArguments : Array

func _init(
	callKey : Funcs = Funcs.ChangeHealth, 
	delay : float = 0, 
	callableArguments : Array = []) -> void:
	self.callKey = callKey
	self.delay = delay
	self.callableArguments = callableArguments
	

func changeHealth(primary : Combatant, secondary : Combatant, value: int):
	primary.current_health += value
	
	
func sticky(primary : Combatant, secondary : Combatant, offset : int):
	var diff = primary.tweenStartingPosition - secondary.tweenStartingPosition
	var unit = diff / diff.length()	
	primary.attachToOther(secondary, unit * abs(offset))
