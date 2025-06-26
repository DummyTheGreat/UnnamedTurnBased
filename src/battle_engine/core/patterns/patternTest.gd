extends TextureRect

@onready var patternBounds : Polygon2D = $PatternBounds

@onready var testAB : RayCast2D = $AB
@onready var testBC : RayCast2D = $BC


var theStrokes : Array[Array] = []
var currentStroke : Array[Vector2] = []
var somePoints = []
var startingPos : Vector2
var endingPos : Vector2

# Remove extruded nodes that are within the triangle formed by the
# previous extrude, next extrude, and the original current point

# Another idea is convert polylines to a chain of lines or a path 2d and
# then either compare the point structure against a pattern or generaate a line or curve
# of best fit for the points of the polyline


#func getPolygonArea(poly : Polygon2D) -> int:
	#var boundArea : int = 0
	#var triangles = Geometry2D.triangulate_polygon(poly.polygon)
	#for i in range(0, len(triangles), 3):
		#var t1 = patternBounds.polygon[triangles[i]]
		#var t2 = patternBounds.polygon[triangles[i + 1]]
		#var t3 = patternBounds.polygon[triangles[i + 2]]
		### A = (1/2) |x1(y2 − y3) + x2(y3 − y1) + x3(y1 − y2)|
		#boundArea += (0.5) * abs(
			#t1.x * (t2.y - t3.y) + 
			#t2.x * (t3.y - t1.y) +
			#t3.x * (t1.y - t2.y)
		#)
	#return boundArea
	
func lineSign(pt : Vector2, v1 : Vector2, v2 : Vector2) -> float:
	return (v2.y - v1.y) * (pt.x - v1.x) - (v2.x - v1.x) * (pt.y - v1.y)
	
#func extrudePoint(point : Vector2, prevPoint, nextPoint, width : int, prevExtrude):
	#var unitDirection : Vector2
	#if prevPoint == null:
		#unitDirection = (nextPoint - point) / (nextPoint - point).length()
		## Counter-clockwise is always the left point, clockwise is always the right point
		#var rotatedCCW = Vector2(-1 * unitDirection.y, unitDirection.x)
		#var rotatedCW = Vector2(unitDirection.y, -1 * unitDirection.x)
		#return [
			#point + (width * 0.5) * rotatedCCW,
			#point + (width * 0.5) * rotatedCW
		#]
	#elif nextPoint == null:
		#unitDirection = (point - prevPoint) / (point - prevPoint).length()
		## Counter-clockwise is always the left point, clockwise is always the right point
		#var rotatedCCW = Vector2(-1 * unitDirection.y, unitDirection.x)
		#var rotatedCW = Vector2(unitDirection.y, -1 * unitDirection.x)
		#return [
			#point + (width * 0.5) * rotatedCCW,
			#point + (width * 0.5) * rotatedCW
		#]
	#else:
		#var TwoPies = 2 * PI
		#var BA = prevPoint - point
		#var BC = nextPoint - point
		#var innerAngle = acos(BA.dot(BC) / (BA.length() * BC.length()))
		#var outerAngle = TwoPies - innerAngle
		## Angle respective to origin (positive x-axis)
		#var nextLineAngle = atan2(BC.y, BC.x)
		#var prevLineAngle = atan2(BA.y, BA.x)
#
		#var halfInner = innerAngle * 0.5
		#var firstCalc : float
		#var secondCalc : float
		## Get the angles of at which the extruded points should be placed at in relation to the x-axis
		#if nextLineAngle <= prevLineAngle:
			#firstCalc = nextLineAngle + innerAngle * 0.5
			#secondCalc = nextLineAngle + innerAngle + outerAngle * 0.5
		#else:
			#firstCalc = prevLineAngle + innerAngle * 0.5
			#secondCalc = prevLineAngle + innerAngle + outerAngle * 0.5
		#
		## Extruded points
		#var p1 = Vector2(
			#point.x + width * 0.5 * cos(firstCalc),
			#point.y + width * 0.5 * sin(firstCalc))
		#var p2 = Vector2(
			#point.x + width * 0.5 * cos(secondCalc),
			#point.y + width * 0.5 * sin(secondCalc))
		## Determines which side the point is in relation to the line or something???
#
		#var isLeft = (
			#(point.x - prevPoint.x) * (p1.y - prevPoint.y) - 
			#(point.y - prevPoint.y) * (p1.x - prevPoint.x))
		#
		### Always return left first, and then right
		#if isLeft > 0:
			#return [p1, p2]
		#return [p2, p1]
	
#func cleanPoints(extrudeList : Array, pointList : Array):
	#
	#var newList = [extrudeList[0]]
	#var i = 1
	#var j = 1
	#while i < len(extrudeList) - 1:
		#var v1 = extrudeList[j - 1]
		#var v2 = extrudeList[i + 1]
		#var v3 = pointList[i]
		#var pt = extrudeList[i]
		#
		#var d1 = lineSign(pt, v1, v2)
		#var d2 = lineSign(pt, v2, v3)
		#var d3 = lineSign(pt, v3, v1)
		#print(d1)
		#
		#var negSide = d1 < 0 or d2 < 0 or d3 < 0
		#var posSide = d1 > 0 or d2 > 0 or d3 > 0
		#
		#i += 1
		#if not (negSide and posSide):
			## remove/skip
			#pass
		#else:
			#j = i
			#newList.append(pt)
			#
	#newList.append(extrudeList[-1])
	#return newList
		

func _ready() -> void:
	pass
	# getPolygonArea(patternBounds)
	# Point, Previous Point, Next Point
	

func getBestSkeleton():
	var temp = get_tree().get_nodes_in_group("Poly Blocks")
	var polyBlocks : Array[Polygon2D] = temp
	for poly in polyBlocks:
		pass
		
	# Basically start from the polygon that encompasses the starting point
	# 


func createTween():
	var lineFillTween = get_tree().create_tween()

func _input(event: InputEvent) -> void:		
		
	if event is InputEventMouseButton:
		if event.pressed:
			startingPos = event.position
		else:
			endingPos = event.position
			if len(currentStroke) < 2:
				return
			theStrokes.append(currentStroke)
			currentStroke = []
			var newLine = Line2D.new()
			newLine.add_point(startingPos)
			newLine.add_point(endingPos)
			self.add_child(newLine)
		
	#if event is InputEventMouseMotion and is_dragging:
		#pass
		
		#var newPoly = Polygon2D.new()
		#newPoly.color = Color.DARK_CYAN
		#var extrudedPoints = extrudePoint(
			#currentStroke[0], null, currentStroke[1], 20, [])
		#var leftPoints = [extrudedPoints[0]]
		#var rightPoints = [extrudedPoints[1]]
		#for i in range(1, len(currentStroke) - 1):
			#extrudedPoints = extrudePoint(
				#currentStroke[i],
				#currentStroke[i - 1],
				#currentStroke[i + 1],
				#20,
				#extrudedPoints
			#)
			#leftPoints.append(extrudedPoints[0])
			#rightPoints.append(extrudedPoints[1])
		#extrudedPoints = extrudePoint(
			#currentStroke[-1], currentStroke[-2], null, 20, extrudedPoints)
		#leftPoints.append(extrudedPoints[0])
		#rightPoints.append(extrudedPoints[1])
		#rightPoints.reverse()
		#leftPoints = cleanPoints(leftPoints, currentStroke)
		#rightPoints = cleanPoints(rightPoints, currentStroke)
		#leftPoints.append_array(rightPoints)
		#newPoly.polygon = PackedVector2Array(leftPoints)
		#newPoly.uv = PackedVector2Array(leftPoints)
		#somePoints = leftPoints
		#self.add_child(newPoly)

			
	if not Input.is_action_pressed("LeftClick"):
		return
	
	currentStroke.append(event.position)
	queue_redraw()

func _draw() -> void:
	#if len(currentStroke) >= 2:
		#draw_polyline(currentStroke, Color.WHITE_SMOKE, 20.0, false)
		#for point in currentStroke:
			#draw_circle(point, 10.0, Color.WHITE_SMOKE)
	#for p in somePoints:
		#draw_circle(p, 2.0, Color.WHITE_SMOKE)
	#for stroke in theStrokes:
		##draw_polyline(stroke, Color.WHITE_SMOKE, 10.0, false)
		#for point in stroke:
			#draw_circle(point, 2.0, Color.LAVENDER)
	pass
		
		
#func _process(delta: float) -> void:
