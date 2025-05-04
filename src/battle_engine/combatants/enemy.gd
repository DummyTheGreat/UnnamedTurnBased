class_name Enemy
extends CharacterStats


var healthBar = null
# Called when the node enters the scene tree for the first time.
func _ready():
	
	super._ready()
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
	
	self.moves = [
		load("res://src/battle_engine/resources/moves/sword_pierce.tres"),
		load("res://src/battle_engine/resources/moves/sword_slash.tres")
	]
	
	self.comboChains = [
		load("res://src/battle_engine/resources/combos/swordSlashDouble.tres"),
		load("res://src/battle_engine/resources/combos/sword_0_2.tres")
	]
	

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
	if self.current_health != healthBar.value:	
		healthBar.value = self.current_health
