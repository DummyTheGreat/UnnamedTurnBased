extends Resource
class_name CombatMove

## A Combat Move is a custom Data Object part of a Combo's "move list". It holds 
## the data for defining what kind of effect a move will have in a combo and 
## various properties for configuration

enum Processes {Collision, Timing}

enum Effects {None, Sticky}

var effectDict : Dictionary = {
	Effects.None : null,
	Effects.Sticky : sticky
}

@export var name: String ## Name of the move
## NOTE: Maybe create separate classes for each weapon if things get crazy
@export var weapon: int ## The ID value for the type of weapon used in the move
@export var damage: int ## The base damage value of the move
@export var attackVariant: String ## The type of attack used with the weapon (Slash, Pierce, Strike)
@export var reactionTime: float ## The duration of time the move takes to travel along ReactionPath
@export var minimumDistanceToTargets: int ## How close the the user of the move has to their targets to execute the move
@export var maxTargets : int ## How many targets can be selected
@export var damageProcessing : Processes
@export var moveEffect : Effects
@export var effectArguments : Array
## movement animation
@export var attackerAnimationEase: Tween.EaseType
@export var attackerAnimationProperties : Array[TweenProperty]
@export var recieverAnimationEase : Tween.EaseType
@export var recieverAnimationProperties : Array[TweenProperty]


func _init(
	name : String = "",
	weapon : int = 0, 
	damage : int = 1,
	attackVariant : String = "slash", 
	reactionTime : float = 1.0,
	minimumDistanceToTargets : int = 100,
	maxTargets : int = 1,
	damageProcessing : Processes = Processes.Collision,
	moveEffect : Effects = Effects.None,
	effectArguments : Array = [],
	attackerAnimationEase : Tween.EaseType = Tween.EASE_IN_OUT,
	attackAnimationProperties : Array[TweenProperty] = [],
	recieverAnimationEase : Tween.EaseType = Tween.EASE_IN_OUT,
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
	self.moveEffect = moveEffect
	self.effectArguments = effectArguments
	self.attackerAnimationEase = attackerAnimationEase
	self.attackerAnimationProperties = attackerAnimationProperties
	self.recieverAnimationEase = recieverAnimationEase
	self.recieverAnimationProperties = recieverAnimationProperties
	
	
func sticky(attacker : Combatant, reciever : Combatant):
	reciever.following = attacker
