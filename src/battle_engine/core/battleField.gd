extends Node2D

## The Battle "Field" is the node that holds and controls all of the combatants 
## in the battle

## References
@onready var rotationAngle : float
@onready var camera = $"../BattleCamera"
@onready var focus = $"../BattleCamera/CenterFocus"

	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	var battle = get_parent()
	
	#var allies = get_node("../Field/Allies")
	#for ally in allies.get_children():
		#ally.target_updated.connect(targetUpdated)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
