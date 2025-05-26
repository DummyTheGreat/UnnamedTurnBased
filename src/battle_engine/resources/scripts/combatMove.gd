extends Resource
class_name CombatMove

## A Combat Move is a custom Data Object part of a Combo's "move list". It holds 
## the data for defining what kind of effect a move will have in a combo and 
## various properties for configuration

enum Processes {Collision, Timing}

enum ActionVariant {Slash, Pierce, Strike, Move}

@export var name: String ## Name of the move
## NOTE: Maybe create separate classes for each weapon if things get crazy
@export var weapon: int ## The ID value for the type of weapon used in the move
@export var damage: int ## The base damage value of the move
@export var attackVariant: ActionVariant ## The type of action to be taken
@export var inputKeyName : StringName ## Idk if this will work lol
@export var reactionTime: float ## The duration of time the move takes to travel along ReactionPath
@export var minimumDistanceToTargets: int ## How close the the user of the move has to their targets to execute the move
@export var maxTargets : int ## How many targets can be selected
@export var damageProcessing : Processes
## movement animation
@export var attackerAnimationEase: Tween.EaseType
@export var attackerAnimationProperties : Array[TweenProperty]
@export var recieverAnimationEase : Tween.EaseType
@export var recieverAnimationProperties : Array[TweenProperty]


func _init(
	name : String = "",
	weapon : int = 0, 
	damage : int = 1,
	attackVariant : ActionVariant = ActionVariant.Slash, 
	reactionTime : float = 1.0,
	minimumDistanceToTargets : int = 100,
	maxTargets : int = 1,
	damageProcessing : Processes = Processes.Collision,
	attackerAnimationEase : Tween.EaseType = Tween.EASE_IN,
	attackAnimationProperties : Array[TweenProperty] = [],
	recieverAnimationEase : Tween.EaseType = Tween.EASE_IN,
	recieverAnimationProperties : Array[TweenProperty] = []
	):
	self.name = name
	self.weapon = weapon
	self.damage = damage
	self.attackVariant = attackVariant
	self.reactionTime = reactionTime
	self.minimumDistanceToTargets = minimumDistanceToTargets
	self.maxTargets = maxTargets
	self.damageProcessing = damageProcessing
	self.attackerAnimationEase = attackerAnimationEase
	self.attackerAnimationProperties = attackerAnimationProperties
	self.recieverAnimationEase = recieverAnimationEase
	self.recieverAnimationProperties = recieverAnimationProperties
	
