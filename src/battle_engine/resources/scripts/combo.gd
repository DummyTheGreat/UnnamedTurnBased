extends Resource
class_name Combo

## A Combo is a custom Data Object that holds a list of Combo Move Objects so
## that they may be linked together to form a combo

@export var comboList : Array[CombatMove] ## A list of ComboMoves


func _init(cList: Array[CombatMove] = []):
	comboList = cList
