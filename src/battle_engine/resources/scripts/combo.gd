extends Resource
class_name Combo

@export var name : String
@export var moveList : Array[Move] ## A list of ComboMoves
@export var propertyDrops : Array[StringName]

func _init(
	name: String = "", 
	moveList: Array[Move] = [], 
	propertyDrops : Array[StringName] = []):
	self.name = name
	self.moveList = moveList
	self.propertyDrops = propertyDrops
