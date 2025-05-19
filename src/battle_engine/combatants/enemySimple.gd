class_name EnemySimple
extends Enemy

# Simpleton's name
@export var EnemyType: String = "Simple"

var enemyWeights = [
	{"name": "move", "weight": 5},
	{"name": "combo", "weight": 2},
	{"name": "skill", "weight": 2}
]

# Targets lowest HP ally for now
func _assess_targets(targets):
	print("SIMPLE!")
	# Variables to track lowest HP target
	var low = INF
	var availabletargets = []
	for target in targets:
		if target.current_health < low:
			low = target.current_health
			availabletargets = [target]
		elif target.current_health == low:
			availabletargets.append(target)
		
	return availabletargets[randi() % availabletargets.size()]
	

func _action():
	# Initialize a pool for weighted selection
	# Then add to the pool for however many weights there are
	var pool = []
	for possibleMove in enemyWeights:
		for i in range(possibleMove.weight):
			pool.append(possibleMove.name)
	
	var poolindex = randi() % pool.size()
	var selectedmove = pool[poolindex]
	
	if selectedmove == "move": 
		print("Enemy uses move!")
		var target = self._assess_targets(self.owner.allies)
		var move = moves[randi() % moves.size()]
		enemySignal.emit(self, target, move)
	
	if selectedmove == "combo":
		## TODO Create combos for enemy (parry system)
		print("Enemy uses combo!")
		# var target = self._assess_targets(self.owner.allies)
		# var combo = comboChains[randi() % comboChains.size()]
		# enemySignal.emit(self, target, combo)
	
	if selectedmove == "skill":
		## TODO Change skill targeting (maybe add a different function)
		print("Enemy uses skill!")
		# var target = self._assess_targets(self.owner.allies)
		# var move = moves[randi() % moves.size()]
		# enemySignal.emit(self, target, move)
