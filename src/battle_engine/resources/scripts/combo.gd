class_name Combo
extends Resource

@export var comboList : Array[CombatMove]

var placeholderMoveOne = preload("res://src/battle_engine/resources/moves/sword_slash.tres")

func _init(cList: Array[CombatMove] = []):
	comboList = cList
