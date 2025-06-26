extends QTE
class_name PatternQTE

@onready var template = $Template
@onready var area = $Template/area
@onready var background = $Template/background

var theStrokes : Array[int] = []
var startingPos : Vector2
var endingPos : Vector2
var isPressed : bool = false
var affectedShapes : Array[int] = []
var currentShapeIndex : int = -1
var paintedBlocks : Array[int] = []


# Remove extruded nodes that are within the triangle formed by the
# previous extrude, next extrude, and the original current point

# Another idea is convert polylines to a chain of lines or a path 2d and
# then either compare the point structure against a pattern or generaate a line or curve
# of best fit for the points of the polyline

## Useless for now
func lineSign(pt : Vector2, v1 : Vector2, v2 : Vector2) -> float:
	return (v2.y - v1.y) * (pt.x - v1.x) - (v2.x - v1.x) * (pt.y - v1.y)
	
## **SIGNAL FUNCTION**
## Emits when the player's mouse enters a PolyBlock
## - Sets the current block index to track and queues it to be colored if mouse is down
func mouseEntered(shapeIndex : int):
	currentShapeIndex = shapeIndex
	if isPressed:
		affectedShapes.append(shapeIndex)
	
## **SIGNAL FUNCTION**
## Emits from a PolyBlock when the tween for changing its color finishes
## - Checks for whether all blocks have been filled
func blockFilled(shapeIndex : int, tween : Tween):
	if shapeIndex not in paintedBlocks:
		paintedBlocks.append(shapeIndex)
	
	if len(paintedBlocks) == area.get_child_count():
		submitReaction.emit(1)
		
	tween.kill()
	
	
func _ready() -> void:
	super()
	for child : PolyBlock in area.get_children():
		var poly = Polygon2D.new()
		poly.color = Color.TRANSPARENT
		poly.polygon = child.polygon
		child.add_child(poly)
	area.mouse_shape_entered.connect(mouseEntered)
	
	background.size = template.size


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if currentShapeIndex >= 0:
				affectedShapes.append(currentShapeIndex)
				isPressed = true
			else:
				print('cancel')
		else:
			isPressed = false
			if len(affectedShapes) > 0:
				area.get_child(affectedShapes[0]).fillArea(affectedShapes)
			theStrokes += affectedShapes
			affectedShapes = []

			
	if not Input.is_action_pressed("LeftClick"):
		return
	
	if len(affectedShapes) > 0 and currentShapeIndex == -1:
		print('kill')
