extends Resource
class_name Sequence

enum Type {Attack, Skill, Platform}

@export var name : StringName
@export var chain : Array[SequenceItem]
@export var type : Type
@export var enemyName : StringName
@export var duration : float

func _init(
	name: StringName = "",
	chain: Array[SequenceItem] = [],
	type : Type = Type.Attack,
	enemyName : StringName = "",
	duration : float = 10.0
) -> void:
	self.name = name
	self.chain = chain
	self.type = type
	self.enemyName = enemyName
	self.duration = duration
	
