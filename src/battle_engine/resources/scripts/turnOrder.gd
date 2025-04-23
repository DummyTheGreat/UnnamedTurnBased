extends Resource
class_name TurnOrder

## A TurnOrder is a custom data object that correlates with a combatant. It's 
## used for sorting the speeds of each combatant and determining turn order

@export var speed : int ## Combatant's speed
@export var id : int ## Combatant's combatID

func _init(speedParam : int, idParam : int) -> void:
	speed = speedParam
	id = idParam
