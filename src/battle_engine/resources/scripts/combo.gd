extends Resource
class_name Combo

## A Combo is a custom Data Object that holds a list of Combo Move Objects so
## that they may be linked together to form a combo

@export var name : String
@export var comboList : Array[CombatMove] ## A list of ComboMoves


func _init(nameParam: String = "", comboListParam: Array[CombatMove] = []):
	name = nameParam
	comboList = comboListParam
