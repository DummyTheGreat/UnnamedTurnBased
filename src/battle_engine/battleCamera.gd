extends Camera2D

@onready var target = $Marker2D
var zoomTicks = 0
var speed : float = 5.0

# Called when the node enters the scene tree for the first time.
func _ready():
	self.offset = Vector2(0, 0)
	self.align()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if zoomTicks > 0:
		# Zoom in a very small amount over a set amount of ticks
		self.zoom *= 1.005
		zoomTicks -= 1
	self.global_position = lerp(self.global_position, target.global_position, delta * speed)
