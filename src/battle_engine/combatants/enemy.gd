class_name Enemy
extends Combatant

@onready var battle = self.get_parent().get_parent().get_parent()

# Signals to get move and target from enemy
signal enemySignal(enemy : Enemy, targets : Array[Combatant], move : Combo)

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	
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
	var targets : Array[Combatant] = []
	targets.append(self._assess_targets(self.owner.allies))
	# Randomly selects a move for now
	var move = self.comboChains[randi() % comboChains.size()]
	enemySignal.emit(self, targets, move)
	
	
func _assess_targets(targets):
	# Random target selection
	return targets[randi() % targets.size()]
