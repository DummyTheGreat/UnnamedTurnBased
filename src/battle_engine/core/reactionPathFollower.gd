class_name ReactionPathFollower
extends PathFollow2D

## A ReactionPathFollower holds the data for the type of input displayed for a reaction on the
## top reaction UI bar. It travels along the "ReactionPath" node.

## References
@onready var timer : Timer
@onready var label : Label
@onready var reactionArea : Area2D

var attackVariant : String ## The type of attack variant that the requested input should match to
var bufferTime : float ## The amount of time it takes for this node to fully traverse the path
var prevFollower : ReactionPathFollower

signal nextReaction()

##*Signal Function*
## Emits when the prior reaction follower finishes
func startTimer():
	timer.start()

func endFollower():
	nextReaction.emit()
	self.queue_free()

func _init(p_attackVariant: String, p_bufferTime: float, prevFollower : ReactionPathFollower) -> void:
	self.attackVariant = p_attackVariant
	self.bufferTime = p_bufferTime
	self.prevFollower = prevFollower


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = bufferTime
	timer.one_shot = true
	
	timer.timeout.connect(endFollower)
	
	label = Label.new()
	label.text = InputMap.action_get_events(attackVariant)[0].as_text().split(" ")[0]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	reactionArea = Area2D.new()
	var collisionBox = CollisionShape2D.new()
	var rectShape = RectangleShape2D.new()
	rectShape.size = Vector2(60, 60)
	collisionBox.shape = rectShape
	reactionArea.add_child(collisionBox)
	
	self.add_child(timer)
	self.add_child(label)
	self.add_child(reactionArea)
	
	if prevFollower == null:
		startTimer()
	else:
		prevFollower.nextReaction.connect(self.startTimer)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer.time_left <= 1 and not timer.is_stopped():
		self.progress_ratio = 1 - (1 / timer.wait_time) * timer.time_left
