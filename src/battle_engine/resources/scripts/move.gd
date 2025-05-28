extends Resource
class_name Move

## A Move is a custom Data Object that holds a list of combat action Objects so
## that they may be linked together to form a move

@export var name : String
@export var actionList : Array[CombatAction] ## A list of ComboMoves


func _init(name: String = "", actionList: Array[CombatAction] = []):
	self.name = name
	self.actionList = actionList
