class_name CombatMove
extends Resource



@export var weapon: int
@export var damage: int
@export var attackVariant: int
@export var playerSpeed: int
@export var targetVelocity: Vector2
@export var reactionTime: float
@export var distance: float
# @export var animation: AnimatedSprite2D

func _init(
	weaponParam =0, 
	damageParam = 1,
	attackVariantParam = 0, 
	playerSpeedParam = 1, 
	targetVelocityParam = Vector2(0, 0),
	reactionTimeParam = 1.0,
	distanceParam = 100.0
	):
	weapon = weaponParam
	damage = damageParam
	attackVariant = attackVariantParam
	playerSpeed = playerSpeedParam
	targetVelocity = targetVelocityParam
	reactionTime = reactionTimeParam
	distance = distanceParam
