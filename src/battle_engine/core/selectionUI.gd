extends Control

@onready var selectionTheme = preload("res://assets/themes/battleSelectionTheme.tres")

var pivotPoint : Control = null
var selectionList : VBoxContainer = null

signal initCombatState(selectionChoice: String, listChoice: String)

func _ready() -> void:
	
	assert(self.get_parent() != null)
	var battleEngine = self.get_parent().get_parent().get_parent().get_parent()
	
	# Signal Connections
	initCombatState.connect(battleEngine.read_ui_input_data)
	
	# Self initialization
	var textureSize = Vector2(32, 32)
	self.anchor_left = 0.5
	self.anchor_top = 0.5
	self.anchor_right = 0.5
	self.anchor_bottom = 0.5
	self.offset_left = textureSize.x * -0.5
	self.offset_top = textureSize.y * -0.5
	self.offset_right = textureSize.x * 0.5
	self.offset_bottom = textureSize.y * 0.5
	
	pivotPoint = Control.new()
	pivotPoint.offset_left = textureSize.x * 0.5
	pivotPoint.offset_top = textureSize.y * 0.5
	pivotPoint.offset_right = 0
	pivotPoint.offset_bottom = 0
	pivotPoint.name = "Pivot Point"
	self.add_child(pivotPoint)
		
	var movesButton = Button.new()
	movesButton.name = "Moves Button"
	movesButton.text = "moves"
	movesButton.theme = selectionTheme
	movesButton.position = Vector2(40, -40 + movesButton.get_minimum_size().y * -0.5)
	movesButton.pressed.connect(_moves_button_pressed.bind("moves"))
	pivotPoint.add_child(movesButton)

	var combosButton = Button.new()
	combosButton.name = "Combos Button"
	combosButton.text = "Combos"
	combosButton.theme = selectionTheme
	combosButton.position = Vector2(60, combosButton.get_minimum_size().y * -0.5)
	combosButton.pressed.connect(_moves_button_pressed.bind("combos"))
	#combosButton.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	pivotPoint.add_child(combosButton)
	
	var skillsButton = Button.new()
	skillsButton.name = "Skills Button"
	skillsButton.text = "Skills"
	skillsButton.theme = selectionTheme
	skillsButton.position = Vector2(40, 40 + skillsButton.get_minimum_size().y * -0.5)
	pivotPoint.add_child(skillsButton)
	
	selectionList = VBoxContainer.new()
	selectionList.name = "BattleSelectionList"
	self.offset_left = textureSize.x * 0.5
	self.offset_top = textureSize.y * -0.5
	self.offset_right = textureSize.x * 0.5
	self.offset_bottom = textureSize.y * 0.5
	
	self.add_child(selectionList)
	
func initMoves(label: Button) -> void:
	for move in self.get_parent().moves:
		label = Button.new()
		label.custom_minimum_size = Vector2(100, 20)
		label.theme = selectionTheme
		label.text = move.name
		label.name = move.name
		label.pressed.connect(_list_button_pressed.bind("moves", move.name))
		selectionList.add_child(label)
		
func initCombos(label: Button) -> void:
	for combo in self.get_parent().comboChains:
		label = Button.new()
		label.custom_minimum_size = Vector2(100, 20)
		label.theme = selectionTheme
		label.text = combo.name
		label.name = combo.name
		label.pressed.connect(_list_button_pressed.bind("combos", combo.name))
		selectionList.add_child(label)

	
func _moves_button_pressed(selectionChoice: String) -> void:
	
	## TODO: For now lists are initialized on click but should probably be 
	## initialized on ready and then hidden
	var label: Button
	if selectionChoice == "moves":
		initMoves(label)
	elif selectionChoice == "combos":
		initCombos(label)

	label = Button.new()
	label.custom_minimum_size = Vector2(100, 20)
	label.theme = selectionTheme
	label.text = "Back"
	label.name = "Back"
	label.pressed.connect(_back_button_pressed)
	selectionList.add_child(label)
	
	selectionList.visible = true
	pivotPoint.visible = false
	
func _back_button_pressed() -> void:
	pivotPoint.visible = true
	selectionList.visible = false
	for child in selectionList.get_children():
		selectionList.remove_child(child)
		child.queue_free()
	
func _list_button_pressed(selectionChoice: String, listChoice: String) -> void:
	selectionList.visible = false
	pivotPoint.visible = false
	initCombatState.emit(selectionChoice, listChoice)
	
	
## *Signal Function*
## Emitted by battle.gd upon combat reset
func resetUI():
	pivotPoint.visible = true
	for child in selectionList.get_children():
		selectionList.remove_child(child)
		child.queue_free()
	self.queue_free()
	
	
	
	
	
