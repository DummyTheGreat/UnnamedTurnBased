extends CharacterStatusUI
class_name AllyStatusUI

@onready var comboText : Label
@onready var comboPoints : ProgressBar
@onready var comboValue : Label
@onready var skillText : Label
@onready var skillPoints : ProgressBar
@onready var skillValue : Label

func _ready() -> void:
	super()
	
	if self.get_parent().get_child_count() == 1:
		comboText = Label.new()
		comboText.name = "ComboText"
		comboText.text = "CP"
		comboText.custom_minimum_size = Vector2(20, 16)
		comboText.add_theme_font_size_override("font_size", 10)
		comboText.vertical_alignment
		comboText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		skillText = Label.new()
		skillText.name = "SkillText"
		skillText.text = "SP"
		skillText.custom_minimum_size = Vector2(20, 16)
		skillText.add_theme_font_size_override("font_size", 10)
		skillText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
					
		self.texts.add_child(comboText)
		self.texts.add_child(skillText)
	
	comboPoints = ProgressBar.new()
	comboPoints.name = "ComboPoints"
	comboPoints.show_percentage = false
	comboPoints.step = 1.0
	comboPoints.custom_minimum_size = Vector2(80, 16)
	
	skillPoints = ProgressBar.new()
	skillPoints.name = "SkillPoints"
	skillPoints.show_percentage = false
	skillPoints.step = 1.0
	skillPoints.custom_minimum_size = Vector2(80, 16)
	
	self.bars.add_child(comboPoints)
	self.bars.add_child(skillPoints)
	
	comboValue = Label.new()
	comboValue.name = "HealthValue"
	comboValue.custom_minimum_size = Vector2(20, 16)
	comboValue.add_theme_font_size_override("font_size", 10)
	
	skillValue = Label.new()
	skillValue.name = "HealthValue"
	skillValue.custom_minimum_size = Vector2(20, 16)
	skillValue.add_theme_font_size_override("font_size", 10)

	self.values.add_child(comboValue)
	self.values.add_child(skillValue)

## *Signal Function*
## Emits from battle upon a new character turn
func updateCharacter():
	super()
