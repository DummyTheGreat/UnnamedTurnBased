class_name CharacterStats
extends CharacterBody2D

@export var max_health: int = 20
@export var current_health: int = 20
@export var base_damage: int = 5
@export var action_cooldown: int = 3
@export var skill_points: int = 10
@export var speed: int = 10
@export var comboChains: Array[Combo] = []
@export var characterName: String = ""

var combatID : int

func _init() -> void:
	combatID = Globals.combatantID
	Globals.combatantID += 1
