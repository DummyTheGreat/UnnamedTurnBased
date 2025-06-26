extends Action
class_name CombatAction

enum ActionVariant {Slash, Pierce, Strike, Move}

@export var attackVariant: ActionVariant ## The type of action to be taken
@export var inputKeyName : StringName ## Idk if this will work lol


func _init(
	name : String = "",
	weapon : int = 0, 
	damage : int = 1,
	attackVariant : ActionVariant = ActionVariant.Slash, 
	inputKeyName : StringName = "SlashAction",
	reactionTime : float = 1.0,
	minimumDistanceToTargets : int = 100,
	maxTargets : int = 1,
	damageProcessing : Processes = Processes.Collision,
	attackAnimationProperties : Array[TweenProperty] = [],
	recieverAnimationProperties : Array[TweenProperty] = []
	):
	super(
		name, 
		weapon, 
		damage, 
		reactionTime, 
		minimumDistanceToTargets, 
		maxTargets, 
		damageProcessing,
		attackAnimationProperties, 
		recieverAnimationProperties)
	self.attackVariant = attackVariant
	self.inputKeyName = inputKeyName	
