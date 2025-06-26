extends Resource
class_name Action

enum Processes {Collision, Timing}

@export var name: String ## Name of the action
## NOTE: Maybe create separate classes for each weapon if things get crazy
@export var weapon: int ## The ID value for the type of weapon used in the move
@export var damage: int ## The base damage value of the move
@export var reactionTime: float ## The duration of time the move takes to travel along ReactionPath
@export var minimumDistanceToTargets: int ## How close the the user of the move has to their targets to execute the move
@export var maxTargets : int ## How many targets can be selected
@export var damageProcessing : Processes
@export var attackerAnimationProperties : Array[TweenProperty]
@export var recieverAnimationProperties : Array[TweenProperty]

func _init(
	name : String = "",
	weapon : int = 0, 
	damage : int = 1,
	reactionTime : float = 1.0,
	minimumDistanceToTargets : int = 100,
	maxTargets : int = 1,
	damageProcessing : Processes = Processes.Collision,
	attackAnimationProperties : Array[TweenProperty] = [],
	recieverAnimationProperties : Array[TweenProperty] = []
) -> void:
	self.name = name
	self.weapon = weapon
	self.damage = damage
	self.reactionTime = reactionTime
	self.minimumDistanceToTargets = minimumDistanceToTargets
	self.maxTargets = maxTargets
	self.damageProcessing = damageProcessing
	self.attackerAnimationProperties = attackerAnimationProperties
	self.recieverAnimationProperties = recieverAnimationProperties
	
