extends Control
class_name Reactor

@onready var circle : TextureRect = $ReactionCircle
@onready var ring : TextureRect = $ReactionRing
@onready var inputKeyLabel : Label = $ReactionCircle/InputKeyLabel
@onready var timer : Timer = $Timer

var isActive : bool
var index : int
var reactionTime : float
var inputAction : String
var shrinkFadeInTween : Tween
var nextReactor : Reactor

var startingDiff : int

##*Signal Function*
## Emits when the prior reaction follower finishes
func startTimer():
	shrinkFadeInTween.play()
	timer.start()

	self.custom_minimum_size = Vector2(256, 256)
	self.modulate.a = 1.0
	circle.set_anchor_and_offset(SIDE_LEFT, 0.5, -64)
	circle.set_anchor_and_offset(SIDE_TOP, 0.5, -64)
	circle.set_anchor_and_offset(SIDE_RIGHT, 0.5, 64)
	circle.set_anchor_and_offset(SIDE_BOTTOM, 0.5, 64)
	
func getIndex():
	return self.index
	
func end():
	shrinkFadeInTween.stop()
	shrinkFadeInTween.kill()
	self.queue_free()
	
func getDifferenceScore():
	var circleRadius : float = circle.size.x * 0.5
	var ringRadius : float = ring.size.x * 0.5
	return 1 - ((ringRadius - circleRadius) / startingDiff)
	
func _ready() -> void:
	
	startingDiff = ring.size.x * 0.5 - circle.size.x * 0.5
	
	ring.modulate.a = 0
	shrinkFadeInTween = get_tree().create_tween()
	shrinkFadeInTween.pause()
	shrinkFadeInTween.set_parallel(true)
	shrinkFadeInTween.tween_property(ring, "modulate:a", 1, reactionTime)
	shrinkFadeInTween.tween_property(ring, "offset_left", circle.offset_left, reactionTime)
	shrinkFadeInTween.tween_property(ring, "offset_top", circle.offset_top, reactionTime)
	shrinkFadeInTween.tween_property(ring, "offset_right", circle.offset_right, reactionTime)
	shrinkFadeInTween.tween_property(ring, "offset_bottom", circle.offset_bottom, reactionTime)
	
	inputKeyLabel.text = inputAction
	
	timer.wait_time = reactionTime + (reactionTime * 0.05)
	
	if not isActive:
		self.custom_minimum_size = Vector2(64, 256)
		self.modulate.a = 0.5
		circle.set_anchor_and_offset(SIDE_LEFT, 0.5, -32)
		circle.set_anchor_and_offset(SIDE_TOP, 0.5, -32)
		circle.set_anchor_and_offset(SIDE_RIGHT, 0.5, 32)
		circle.set_anchor_and_offset(SIDE_BOTTOM, 0.5, 32)


func _process(delta: float) -> void:
	pass
