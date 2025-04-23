class_name CameraFocus
extends Marker2D

@onready var first = self.get_parent()
@onready var second = self.get_parent()

signal new_focus(angle : float)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.global_position = (first.global_position + second.global_position) * 0.5
