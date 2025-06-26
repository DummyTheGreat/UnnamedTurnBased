extends CollisionPolygon2D
class_name PolyBlock

@onready var pattern = self.owner

@export var neighbors : Array[PolyBlock]

var neighborIds = []
var centroid = Vector2(0, 0)
var painted = false

func _ready() -> void:
	var sum = Vector2(0, 0)
	for p in self.polygon:
		sum += p
	centroid = sum / len(self.polygon)
	
	for n in neighbors:
		neighborIds.append(n.get_index())
		

func filterByIndex(shape : CollisionPolygon2D, selectedIndices : Array):
	return (shape.get_index() in selectedIndices)
	
func removeSelfAndNeighbors(num):
	return (num != self.get_index())

## Cascades the coloring effect to any neighboring PolyBlocks if they were selected by mouse
func activateNeighbors(shapeIds : Array[int]):
	# Get all shapes in area
	var shapes = self.get_parent().get_children()
	# Filter for all shapes by the player's selection
	var selectedShapes = shapes.filter(filterByIndex.bind(shapeIds))
	# Filter for neighbors that match the selections
	var relevantNeighbors = neighbors.filter(func(num): return (num in selectedShapes))
	for n in relevantNeighbors:
		n.fillArea(shapeIds)
		
		
func highlightArea():
	var poly : Polygon2D = self.get_child(0)
	var lineFillTween = get_tree().create_tween()
	lineFillTween.pause()
	lineFillTween.parallel().tween_property(poly, "color", Color(Color.AZURE, 0.5), 0.1)
	lineFillTween.play()

## Fills the PolyBlock with a color using a tween
func fillArea(shapeIds : Array[int]):
	var poly : Polygon2D = self.get_child(0)
	var filteredIds = shapeIds.filter(removeSelfAndNeighbors)
	
	#var gradient = Gradient.new()
	#gradient.colors = [Color.WHITE, Color.TRANSPARENT]
	#var gradientTexture = GradientTexture2D.new()
	#gradientTexture.gradient = gradient
	#gradientTexture.fill_from = Vector2(0.0, 0.5)
	#gradientTexture.fill_to = Vector2(1.0, 0.5)
	#poly.texture = gradientTexture
	
	var lineFillTween = get_tree().create_tween()
	lineFillTween.pause()
	lineFillTween.parallel().tween_property(poly, "color", Color.AZURE, 0.1)
	lineFillTween.parallel().tween_callback(activateNeighbors.bind(filteredIds)).set_delay(0.05)
	lineFillTween.finished.connect(owner.blockFilled.bind(self.get_index(), lineFillTween))
	lineFillTween.play()
