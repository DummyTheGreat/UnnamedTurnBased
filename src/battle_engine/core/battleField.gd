extends Node2D

## The Battle "Field" is the node that holds and controls all of the combatants 
## in the battle

## References
@onready var rotationAngle : float
@onready var camera = $"../BattleCamera"
@onready var focus = $"../BattleCamera/CenterFocus"

## *Signal Function*
## Sets the position of a Marker2D child node of the camera to center on a position
## between two node referred to as "first" and "second"
## Emits when a combatant (ally.gd) changes the target of it's attack
func _target_updated():

	## TODO: This signal might be able to be moved to battleCamera.gd and/or cameraFocus.gd
	var p1 = focus.first.global_position
	var p2 = focus.second.global_position
	camera.zoomTicks = 100
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	var allies = get_node("../Field/Allies")
	for ally in allies.get_children():
		ally.target_updated.connect(_target_updated)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
