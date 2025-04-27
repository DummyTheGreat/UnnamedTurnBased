class_name CharacterStats
extends CharacterBody2D

## Parent node of combatant types for defining their stats and identifiers

@export var max_health: int = 20
@export var current_health: int = 20 ## Cannot be greater than max_health
@export var base_damage: int = 5 ## Scaled by modifiers
@export var skill_points: int = 10 ## The number of available skill points to be use in a battle
@export var speed: int = 10 ## Base speed
@export var comboChains: Array[Combo] = [] ## A list of all combos available to the character
@export var characterName: String = "" ## In-game character name for display
@export var defaultActionGauge: int = 1000 ##
@export var actionGauge: int  ##Base Action Gauge
@export var actionValue: int  ##Base Action Value

var combatID : int ## Unique identifier used in combat

func _init() -> void:
	combatID = Globals.combatantID
	Globals.combatantID += 1
	actionGauge = defaultActionGauge

func _ready() -> void:
	actionValue = actionGauge / speed
