extends PathFollow2D

var currentPath : Path2D
var is_dragging = false
var turnPoints : Dictionary = {
	0 : 75
}

var nextTurnIndex = 0
var points = []

func _input(event: InputEvent) -> void:
	#print(event)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			
	if event is InputEventMouseMotion and is_dragging:
		var motionAngle = atan2(event.velocity.y, event.velocity.x)
		var pathVec = points[-1] - points[0]
		var pathAngle = atan2(pathVec.y, pathVec.x)
		if abs(angle_difference(motionAngle, pathAngle)) < 0.3:
			self.progress_ratio += 0.1
		

func _ready():
	currentPath = get_parent()
	points = currentPath.curve.tessellate()
	print(points)
