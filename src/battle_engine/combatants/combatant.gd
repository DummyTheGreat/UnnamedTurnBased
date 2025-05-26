extends CharacterBody2D
class_name Combatant

## Parent node of combatant types for defining their stats and identifiers

@onready var collider : CollisionShape2D = $CollisionShape2D

@export var max_health: int = 20
@export var current_health: int = 20 ## Cannot be greater than max_health
@export var base_damage: int = 5 ## Scaled by modifiers
@export var skill_points: int = 10 ## The number of available skill points to be use in a battle
@export var speed: int = 10 ## Base speed
@export var moves: Array[CombatMove] = [] ## A list of all SINGULAR moves available to the character
@export var comboChains: Array[Combo] = [] ## A list of all combos available to the character
@export var characterName: String = "" ## In-game character name for display
@export var defaultActionGauge: int = 1000 ##
@export var actionGauge: int  ##Base Action Gauge
@export var actionValue: int  ##Base Action Value

var targetted : bool = false
var baseBattlePosition : Vector2 = Vector2(0, 0)
var tweenStartingPosition : Vector2 = Vector2(0, 0) ## Tweens are too fast, so memorizing the starting position helps with applying effects correctly
var following : Combatant = null ## Who the combatant is "attached to"
var followingOffset : Vector2 = Vector2(0, 0)

var combatID : int ## Unique identifier used in combat
	
signal characterTurn(character : Combatant)

func turnPassed() -> void:
	if actionGauge >= 0 :
		actionGauge -= speed
	if speed != 0 :
		actionValue = actionGauge / speed

func actionAdvanceGauge() -> void:
	turnPassed()
	if(actionGauge <= 0):
		characterTurn.emit(self)

func turnEndActionGauge() -> void:
	actionGauge += defaultActionGauge
	
func _init() -> void:
	combatID = Globals.combatantID
	Globals.combatantID += 1
	actionGauge = defaultActionGauge
	
func attachToOther(leader : Combatant, offset : Vector2):
	following = leader
	followingOffset = offset

func _ready() -> void:
	characterTurn.connect(self.get_parent().get_parent().get_parent().characterTurn)
	actionValue = actionGauge / speed
	
	var collisionArea = Area2D.new()
	collisionArea.name = "CollisionArea"
	self.add_child(collisionArea)
	var collisionShape = CollisionShape2D.new()
	collisionShape.name = "CollisionAreaShape"
	collisionShape.shape = self.collider.shape
	collisionArea.add_child(collisionShape)
	collisionArea.area_entered.connect(self.owner.handleCombatantAreaEntered.bind(collisionArea))
	
	
func _process(delta: float) -> void:
	if following != null:
		self.position = following.position + followingOffset
	self.move_and_slide()
		
