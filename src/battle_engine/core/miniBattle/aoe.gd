extends Area2D
class_name AOE

## A stationary type of attack that forms from a central point

@onready var timer : Timer = $Timer
@onready var animator : AnimationPlayer = $Animator

var warningTime : float = 1.0
var effectTime : float = 1.0
var animNames : Array[StringName] = []
var animIndex : int = 0
var shape : Shape2D
var texture : Texture2D
var warning = true


##**SIGNAL FUNCTION**
## Trigger on timer timeout
func playNext():
	animator.stop()
	animator.play(animNames.pop_front())
	timer.start()
	
func end():
	if animNames.is_empty():
		animator.stop()
		self.queue_free()
	if warning:
		warning = false
		timer.wait_time = effectTime
	playNext()

func _ready() -> void:
	
	if animNames.is_empty():
		return
	
	timer.wait_time = warningTime
	timer.timeout.connect(end)
	
	playNext()
