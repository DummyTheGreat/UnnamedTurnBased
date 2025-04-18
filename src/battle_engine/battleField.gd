extends Node2D

@onready var rotationAngle : float
@onready var camera = $"../Camera2D"
@onready var focus = $"../Camera2D/Marker2D"

var rotationTicks = 0

func _target_updated():

	var p1 = focus.first.global_position
	var p2 = focus.second.global_position
	var vel = Vector2(p1 - p2)
	print(p1, " ", p2)
	var angle = acos(vel.dot(p2) / (vel.length() * vel.length()))
	print(angle)
	rotationAngle = angle
	rotationTicks = 100
	camera.zoomTicks = 100
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotationAngle = 0
	
	var allies = get_node("../Field/Allies")
	for ally in allies.get_children():
		ally.target_updated.connect(_target_updated)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
