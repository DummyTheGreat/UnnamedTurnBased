class_name CameraFocus
extends Marker2D

## The CameraFocus is used to get a point of position centered between two nodes that
## the camera is then set to follow

@onready var focusPoints : Array = [self.get_parent()] ## List of focus points

var numPoints : float = 1
## *Signal Function*
## Emits from battle when enemy selections are made
func updateTargetPoints(targetList : Array):
	focusPoints = targetList
	numPoints = float(targetList.size())
	#temp
	get_parent().activateZoom = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var sum = focusPoints.reduce(func(sum, point): return sum + point.position, Vector2(0, 0))
	self.global_position = sum * (1.0 / numPoints)
