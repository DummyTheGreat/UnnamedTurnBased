extends Node

@export var moveName : String
@export var damage : int
@export var variant : String
@export var reactionTime : float
@export var minimumDistance : int
@export var maxTargets : int

func _ready() -> void:
	
	
	
	var newMove = CombatMove.new(
		moveName,
		0,
		damage,
		variant,
		reactionTime,
		minimumDistance,
		maxTargets,
		
	)
	#ResourceSaver.save()
