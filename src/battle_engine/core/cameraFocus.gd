class_name CameraFocus
extends Marker2D

## The CameraFocus is used to get a point of position centered between two nodes that
## the camera is then set to follow

@onready var first = self.get_parent() ## The first node to be used for finding the center point
@onready var second = self.get_parent() ## The second node to be used for finding the center point

## *Signal Function*
## Emits from battle when enemy selections are made
func updateTargetPoints(targetList : Array):
	first = targetList[0]
	second = targetList[1]
	#temp
	get_parent().zoomTicks = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.global_position = (first.global_position + second.global_position) * 0.5
	pass
