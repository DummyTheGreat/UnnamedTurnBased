extends Resource
class_name CombatMove

## A Combat Move is a custom Data Object part of a Combo's "move list". It holds 
## the data for defining what kind of effect a move will have in a combo and 
## various properties for configuration

@export var weapon: int ## The ID value for the type of weapon used in the move
@export var damage: int ## The base damage value of the move
@export var attackVariant: String ## The type of attack used with the weapon (Slash, Pierce, Strike)
@export var playerSpeed: int ## The speed at which the combatant's sprite moves when executing the move
@export var targetVelocity: Vector2 ## The velocity at which the opposing combatant is launched at (knockback)
@export var reactionTime: float ## The duration of time the move takes to travel along ReactionPath

func _init(
	weaponParam =0, 
	damageParam = 1,
	attackVariantParam = "slash", 
	playerSpeedParam = 1, 
	targetVelocityParam = Vector2(0, 0),
	reactionTimeParam = 1.0,
	):
	weapon = weaponParam
	damage = damageParam
	attackVariant = attackVariantParam
	playerSpeed = playerSpeedParam
	targetVelocity = targetVelocityParam
	reactionTime = reactionTimeParam
