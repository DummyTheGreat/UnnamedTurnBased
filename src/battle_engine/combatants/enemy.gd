class_name Enemy
extends CharacterStats


var healthBar = null
# Signals to get move and target from enemy
signal enemySignal(enemy, target, move)

# Called when the node enters the scene tree for the first time.
func _ready():
	var battle = get_parent().get_parent().get_parent()
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
	
	# Enemy signal processing
	enemySignal.connect(battle.processEnemyTurn)
	
	self.moves = [
		load("res://src/battle_engine/resources/moves/sword_pierce.tres"),
		load("res://src/battle_engine/resources/moves/sword_slash.tres")
	]
	
	self.comboChains = [
		load("res://src/battle_engine/resources/combos/swordSlashDouble.tres"),
		load("res://src/battle_engine/resources/combos/sliceAndSkewer.tres")
	]
	

func _action():
	var target = self._assess_targets(self.owner.allies)
	# Randomly selects a move for now
	var move = moves[randi() % moves.size()]
	enemySignal.emit(self, target, move)
	
	
func _assess_targets(targets):
	# Random target selection
	return targets[randi() % targets.size()]
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.current_health != healthBar.value:	
		healthBar.value = self.current_health
