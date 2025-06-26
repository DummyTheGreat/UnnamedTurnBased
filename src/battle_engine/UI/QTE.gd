extends Control
class_name QTE

@onready var timer : Timer = $Timer

signal submitReaction(inputAction : StringName) ## Emites to ReactionUI -> handleReaction

var nextEvent : QTE
var index : int
var isActive : bool
var reactionTime : float

func startTimer():
	timer.start()
	isActive = true
	
func getIndex():
	return self.index
	
func end():
	self.queue_free()
	
func _ready() -> void:
	timer.wait_time = reactionTime + 0.05
