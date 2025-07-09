extends Node2D
class_name BattleSequence

var sequenceName : StringName
var enemyOnScreen : bool = false
var sequence : Sequence
var player : MiniPlayer
var arenaSize : Vector2

const projScene = preload("res://src/battle_engine/core/miniBattle/ProjectileScene.tscn")
const aoeScene = preload("res://src/battle_engine/core/miniBattle/AOE.tscn")

static func initProjectile(
	spd : int, 
	dir : Vector2, 
	pos : Vector2, 
	ang : float,
	shape : Shape2D,
	texture : Texture2D):
	var newProjectile = projScene.instantiate()
	newProjectile.speed = spd
	newProjectile.direction = dir
	newProjectile.position = pos
	newProjectile.rotation = ang
	newProjectile.shape = shape
	newProjectile.texture = texture
	return newProjectile
	
static func initAOE(
	pos : Vector2,
	warningTime : float,
	effectTime : float,
	animList : Array[StringName],
	shape : Shape2D,
	texture : Texture2D):
	var newAOE = aoeScene.instantiate()
	newAOE.position = pos
	newAOE.warningTime = warningTime
	newAOE.effectTime = effectTime
	newAOE.animNames = animList
	newAOE.shape = shape
	newAOE.texture = texture
	return newAOE
	
	
func play():
	pass
	
	
func _init(seq : Sequence, player : MiniPlayer, arenaSize : Vector2) -> void:
	self.sequence = seq
	self.player = player
	self.arenaSize = arenaSize
	

func _ready() -> void:
	for item : SequenceItem in sequence.chain:
		for entity in item.data:
			var startPos : Vector2
			if entity is MiniProperties:
				match entity.posKey:
					entity.Positions.Anchored:
						startPos = entity.Anchored.bindv(entity.posArguments).call(arenaSize)
					entity.Positions.RelativeToPlayer:
						startPos = entity.RelativeToPlayer.bindv(entity.posArguments).call(player.position)
			var sceneEntity
			if entity is ProjectileProperties:
				var dirVec : Vector2
				match entity.dirKey:
					entity.Directions.AtAngle:
						dirVec = entity.AtAngle.bindv(entity.dirArguments).call()
					entity.Directions.TowardsPlayer:
						dirVec = entity.TowardsPlayer.bindv(entity.dirArguments).call(startPos, player.position)
					entity.Directions.TowardsPlayerRandom:
						dirVec = entity.TowardsPlayerRandom.bindv(entity.dirArguments).call(startPos, player.position)
					
				sceneEntity = initProjectile(entity.speed, dirVec, startPos, 
					dirVec.angle(), entity.shape, entity.spriteTexture)
			elif entity is AOEProperties:
				sceneEntity = initAOE(startPos, entity.warningTime, entity.effectTime,
					entity.animationList, entity.shape, entity.spriteTexture)
			add_child(sceneEntity)
