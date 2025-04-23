class_name Enemy
extends CharacterStats

var actionTimer = null
var actionBar = null
var healthBar = null
# Called when the node enters the scene tree for the first time.
func _ready():
	# Action Timer
	actionTimer = Timer.new()
	actionTimer.name = "ActionTimer"
	actionTimer.wait_time = self.action_cooldown
	actionTimer.timeout.connect(_action)
	self.add_child(actionTimer)
	actionTimer.start()
	
	# Action Bar
	actionBar = TextureProgressBar.new()
	actionBar.name = "ActionBar"
	
	var action_bar_blue = Image.new()
	action_bar_blue.load("res://assets/action_bar.png")
	var t = ImageTexture.create_from_image(action_bar_blue)
	
	actionBar.texture_progress = t
	actionBar.scale = Vector2(0.2, 0.2)
	actionBar.set_position(Vector2(-7, -11))
	self.add_child(actionBar)
	
	# Health Bar
	healthBar = TextureProgressBar.new()
	healthBar.name = "HealthBar"
	
	var health_bar_green = Image.new()
	health_bar_green.load("res://assets/health_bar_green.png")
	var t2 = ImageTexture.create_from_image(health_bar_green)

	healthBar.texture_progress = t2
	healthBar.max_value = self.max_health
	healthBar.value = self.current_health
	healthBar.scale = Vector2(0.2, 0.2)
	healthBar.set_position(Vector2(-7, -14))
	self.add_child(healthBar)
	

func _action():
	var target = self._assess_targets(self.owner.allies)
	
	
	
func _assess_targets(targets):
	
	var maximum = 0.0
	var target = 0

	for i in range(len(targets)):
		var damageFreq = float(targets[i].base_damage)# / float(targets[i].action_cooldown)
		var vulnerability = float(targets[i].max_health) / float(targets[i].current_health)
		if damageFreq + vulnerability > maximum:
			maximum = damageFreq + vulnerability
			target = i
		
	return targets[target]
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var percentTime = (actionTimer.wait_time - actionTimer.time_left) / actionTimer.wait_time
	actionBar.value = roundi(percentTime * actionBar.max_value)
	if actionBar.value == actionBar.max_value:
		actionTimer.stop()
		self._action()
		actionTimer.start()
		
	healthBar.value = self.current_health
