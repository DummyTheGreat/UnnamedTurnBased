extends Camera2D

## This script handles the battle camera's positional translation and scaling

## References
@onready var target = $CenterFocus

var zoomTicks = 0 ## A decrementing value used to countdown how long the camera should zoom in
var speed : float = 5.0 ## I need to review what this does lol, something with lerp()

## *Signal Function*
## Called by battle.gd when a turn is ended
func doCameraReset():
	# Rinky Dink ass solution
	self.global_position = Vector2(0, 0)
	target.first = self
	target.second = self
	self.zoom = Vector2(2.0, 2.0)
	

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
