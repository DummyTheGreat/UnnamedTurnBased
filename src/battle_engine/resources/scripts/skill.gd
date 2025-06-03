# Skill class resource
extends Resource
class_name Skill

## A Skill Move is a custom Data Object for a characters skill moves. It defines
## the different effects that a skill could have.

enum skillVariant {Heal, Buff, Debuff, TurnManip, Status}

@export var name: String ## Name of the move
@export skillVariant ##Defines the type of skill used (Heal, Stat Debuffs, Action Manipulation, Status Effects)
@export var cost: int ## Base skill cost
@export var power: int ## Base strength of skill

func _init(
	name : String = "",
	skillVariant : String = "",
	cost : int = 3, 
	power : int = 10
	):
	self.name = name
	self.skillVariant = skillVariant
	self.cost = cost
	self.power = power
