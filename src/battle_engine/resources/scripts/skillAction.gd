extends Action
class_name SkillAction

## A Skill Move is a custom Data Object for a characters skill moves. It defines
## the different effects that a skill could have.

enum SkillVariant {Heal, Buff, Debuff, TurnManip, Status}

@export var skillType : SkillVariant ##Defines the type of skill used (Heal, Stat Debuffs, Action Manipulation, Status Effects)
@export var cost: int ## Base skill cost
@export var pattern: PackedScene

func _init(
	skillType : SkillVariant = SkillVariant.Heal,
	cost : int = 3, 
	):
	super(name, weapon, damage, reactionTime, minimumDistanceToTargets, maxTargets)
	self.skillType = skillType
	self.cost = cost
