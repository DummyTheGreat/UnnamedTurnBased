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


func _init(p_attackVariant: String, p_bufferTime: float) -> void:
	attackVariant = p_attackVariant
	bufferTime = p_bufferTime


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer = Timer.new()
	
	timer.wait_time = bufferTime
	timer.one_shot = true
	
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
	
	timer.start()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer.time_left <= 1:
		self.progress_ratio = 1 - timer.time_left
	if self.progress_ratio == 1.0:
		self.queue_free()
