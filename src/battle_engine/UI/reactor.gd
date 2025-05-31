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

##*Signal Function*
## Emits when the prior reaction follower finishes
func startTimer():
	shrinkFadeInTween.play()
	timer.start()

func endFollower():
	self.queue_free()
	
func getIndex():
	return self.index
	
func getDifferenceScore():
	var startingDiff : float = 64.0
	var circleRadius : float = circle.size.x * 0.5
	var ringRadius : float = ring.size.x * 0.5
	return 1 - ((ringRadius - circleRadius) / startingDiff)
	
func _ready() -> void:
	
	ring.modulate.a = 0
	shrinkFadeInTween = get_tree().create_tween()
	shrinkFadeInTween.pause()
	shrinkFadeInTween.set_parallel(true)
	shrinkFadeInTween.tween_property(ring, "modulate:a", 1, reactionTime)
	shrinkFadeInTween.tween_property(ring, "offset_left", -64, reactionTime)
	shrinkFadeInTween.tween_property(ring, "offset_top", -64, reactionTime)
	shrinkFadeInTween.tween_property(ring, "offset_right", 64, reactionTime)
	shrinkFadeInTween.tween_property(ring, "offset_bottom", 64, reactionTime)
	
	inputKeyLabel.text = inputAction
	
	timer.timeout.connect(endFollower)
	timer.wait_time = reactionTime + (reactionTime * 0.05)


func _process(delta: float) -> void:
	pass
