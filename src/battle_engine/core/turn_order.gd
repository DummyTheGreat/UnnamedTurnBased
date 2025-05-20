extends Control
class_name TurnOrderUI

var characters = null
@onready var vertBox = $VBoxContainer
func _init() -> void:
	pass
	
func _ready() -> void:
	pass
	
func inputList(characterList: Array) -> void: 
	characters = characterList
	updateList()
	
func orderList():
	characters.sort_custom(character_array_sort)
	
func character_array_sort(a: CharacterStats, b: CharacterStats):
	if a.actionValue < b.actionValue:
		return true
	elif a.actionValue == b.actionValue:
		return a is Ally
	return false
		
func updateList():
	for child in vertBox.get_children():
		vertBox.remove_child(child)
		child.queue_free()
	orderList()
	for character in characters:
		var label_node = Label.new()
		label_node.text = character.name + "    " + str(character.actionValue)
		vertBox.add_child(label_node)
