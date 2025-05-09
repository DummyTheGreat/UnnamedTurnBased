class_name CameraFocus
extends Marker2D

## The CameraFocus is used to get a point of position centered between two nodes that
## the camera is then set to follow

@onready var focusPoints : Array = [self.get_parent()] ## List of focus points
## *Signal Function*
## Emits from battle when enemy selections are made
func updateTargetPoints(targetList : Array):
	focusPoints = targetList
	#temp
	get_parent().activateZoom = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var sum : Vector2 = Vector2(0, 0)
	for point in focusPoints:
		sum += point.global_position
	self.global_position = sum * (1.0 / float(focusPoints.size()))
