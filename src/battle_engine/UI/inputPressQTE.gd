extends QTE
class_name InputPressQTE

@onready var circle : TextureRect = $ReactionCircle
@onready var ring : TextureRect = $ReactionRing
@onready var inputKeyLabel : Label = $ReactionCircle/InputKeyLabel

var inputAction : String
var shrinkFadeInTween : Tween
var startingDiff : int

##*Signal Function*
## Emits when the prior reaction follower finishes
func startTimer():
	super()
	shrinkFadeInTween.play()
	self.custom_minimum_size = Vector2(256, 256)
	self.modulate.a = 1.0
	circle.set_anchor_and_offset(SIDE_LEFT, 0.5, -64)
	circle.set_anchor_and_offset(SIDE_TOP, 0.5, -64)
	circle.set_anchor_and_offset(SIDE_RIGHT, 0.5, 64)
	circle.set_anchor_and_offset(SIDE_BOTTOM, 0.5, 64)
	
func end():
	shrinkFadeInTween.stop()
	shrinkFadeInTween.kill()
	super()
	
func getDifferenceScore():
	var circleRadius : float = circle.size.x * 0.5
	var ringRadius : float = ring.size.x * 0.5
	return 1 - ((ringRadius - circleRadius) / startingDiff)
	
func _ready() -> void:
	super()
	
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
		
	if not isActive:
		self.custom_minimum_size = Vector2(64, 256)
		self.modulate.a = 0.5
		circle.set_anchor_and_offset(SIDE_LEFT, 0.5, -32)
		circle.set_anchor_and_offset(SIDE_TOP, 0.5, -32)
		circle.set_anchor_and_offset(SIDE_RIGHT, 0.5, 32)
		circle.set_anchor_and_offset(SIDE_BOTTOM, 0.5, 32)
		
func _input(event: InputEvent) -> void:
	if isActive:
		## TODO: THERE HAS GOT TO BE A BETTER WAY TO DO THIS
		if Input.is_action_just_pressed("SlashAction"):
			submitReaction.emit("SlashAction")
		elif Input.is_action_just_pressed("PierceAction"):
			submitReaction.emit("PierceAction")
		elif Input.is_action_just_pressed("StrikeAction"):
			submitReaction.emit("StrikeAction")
		elif Input.is_action_just_pressed("MoveTowards"):
			submitReaction.emit("MoveTowards")
		elif Input.is_action_just_pressed("MoveAway"):
			submitReaction.emit("MoveAway")
		elif Input.is_action_just_pressed("MoveUp"):
			submitReaction.emit("MoveUp")
