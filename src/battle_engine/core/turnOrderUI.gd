extends Control
class_name TurnOrderUI

var characterLabelList : Array[TurnOrder]

var tempLabelList : Array[TurnOrder]

@onready var vertBox = $VBoxContainer
func _init() -> void:
	pass
	
func _ready() -> void:
	pass
	
func inputList(characterList: Array) -> void: 
	createList(characterList)
	
func createList(characterList: Array) -> void: 
	for character in characterList:
		var labelNode = Label.new()
		characterLabelList.append(TurnOrder.new(character, labelNode))
	for label in characterLabelList:
		vertBox.add_child(label.getLabel())
	updateList()

func addTemp(character: Combatant, actionValue: int) -> void:
	var labelNode = Label.new()
	labelNode.text = character.name + "    " + str(character.actionValue + actionValue)
	labelNode.add_theme_color_override("font_color", Color(255, 0, 0))
	var tempLabel = TurnOrder.new(character, labelNode)
	tempLabel.setTempAV(actionValue)
	tempLabelList.append(tempLabel)
	vertBox.add_child(labelNode)
	updateList()
	
func removeTemp() -> void:
	for label in tempLabelList:
		vertBox.remove_child(label.getLabel())
		label.getLabel().queue_free()
	tempLabelList.clear()
	updateList()
	
func makeText(character: TurnOrder) -> String: 
	return character.getCombatant().name + "    " + str(character.getCombatant().actionValue + character.getTempAV())
	
func updateList():
	var sortedList = (characterLabelList + tempLabelList)
	sortedList.sort_custom(character_array_sort)
	var i : int = 0
	for label in sortedList:
		label.getLabel().text = makeText(label)
		vertBox.move_child(label.getLabel(), i)
		i += 1
	
func character_array_sort(a: TurnOrder, b: TurnOrder):
	var aComb : Combatant = a.getCombatant()
	var aTAV : int = a.getTempAV()
	var bComb : Combatant = b.getCombatant()
	var bTAV : int = b.getTempAV()
	if (aComb.actionValue + aTAV) < (bComb.actionValue + bTAV):
		return true
	elif (aComb.actionValue + aTAV) == (bComb.actionValue + bTAV):
		return aComb is Ally
	return false
		
