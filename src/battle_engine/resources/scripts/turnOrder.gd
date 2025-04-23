extends Resource
class_name TurnOrder

@export var speed : int
@export var id : int

func _init(speedParam : int, idParam : int) -> void:
	speed = speedParam
	id = idParam
