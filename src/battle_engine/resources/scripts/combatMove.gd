extends Resource
class_name CombatMove

## A Combat Move is a custom Data Object part of a Combo's "move list". It holds 
## the data for defining what kind of effect a move will have in a combo and 
## various properties for configuration

@export var name: String ## Name of the move
@export var weapon: int ## The ID value for the type of weapon used in the move
@export var damage: int ## The base damage value of the move
@export var attackVariant: String ## The type of attack used with the weapon (Slash, Pierce, Strike)
@export var playerSpeed: int ## The speed at which the combatant's sprite moves when executing the move
@export var targetVelocity: Vector2 ## The velocity at which the opposing combatant is launched at (knockback)
@export var reactionTime: float ## The duration of time the move takes to travel along ReactionPath
@export var minimumDistanceToTargets: int ## How close the the user of the move has to their targets to execute the move
var attackAnimationEase: Tween.EaseType
var attackAnimationProperties : Array[TweenProperty]

func _init(
	name = "",
	weapon =0, 
	damage = 1,
	attackVariant = "slash", 
	playerSpeed = 1, 
	targetVelocity = Vector2(0, 0),
	reactionTime = 1.0,
	minimumDistanceToTargets = 100,
	
	):
	self.name = name
	self.weapon = weapon
	self.damage = damage
	self.attackVariant = attackVariant
	self.playerSpeed = playerSpeed
	self.targetVelocity = targetVelocity
	self.reactionTime = reactionTime
	self.minimumDistanceToTargets = minimumDistanceToTargets
