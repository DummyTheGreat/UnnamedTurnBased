extends Path2D
class_name MovingPlatform

enum AnimationType {Default}

@export var loopMode : Animation.LoopMode
@export var duration : float
@export var pace : Tween.TransitionType

@onready var follower : PathFollow2D = $PathFollow2D


func _ready() -> void:
	print(duration)
	var tween = self.create_tween()
	tween.stop()
	if not loopMode == Animation.LoopMode.LOOP_NONE:
		tween.set_loops(-1)
	tween.tween_property(
		follower, 
		"progress_ratio", 
		1.0, 
		duration).from(0).set_trans(pace)
		
	if loopMode == Animation.LoopMode.LOOP_PINGPONG:
		tween.tween_property(
			follower, 
			"progress_ratio", 
			0, 
			duration).from(1.0).set_trans(pace)
			
	tween.play()
	
