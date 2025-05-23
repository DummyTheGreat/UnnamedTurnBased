extends HBoxContainer
class_name CharacterStatusUI

@onready var spriteBox : VBoxContainer = $Body/SpriteBox
@onready var nameLabel : Label = $Body/SpriteBox/Name
@onready var spriteImage : TextureRect = $Body/SpriteBox/SpriteImage
@onready var spacer : Control = $Head/Spacer
@onready var texts : VBoxContainer = $Head/Texts
@onready var bars : VBoxContainer = $Body/StatBox/Bars
@onready var values : VBoxContainer = $Body/StatBox/Values

@onready var healthText : Label
@onready var healthPoints : ProgressBar
@onready var healthValue : Label

@onready var healthBarTheme : Theme = preload("res://assets/themes/healthBarTheme.tres")

var registeredCombatant : Combatant = null

func _ready() -> void:
	
	if self.get_parent().get_child_count() == 1:
		healthText = Label.new()
		healthText.name = "HealthText"
		healthText.text = "HP"
		healthText.custom_minimum_size = Vector2(20, 16)
		healthText.add_theme_font_size_override("font_size", 10)
		healthText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		texts.add_child(healthText)
	
	healthPoints = ProgressBar.new()
	healthPoints.name = "HealthPoints"
	healthPoints.show_percentage = false
	healthPoints.step = 1.0
	healthPoints.custom_minimum_size = Vector2(80, 16)
	healthPoints.theme = healthBarTheme
	bars.add_child(healthPoints)
	
	healthValue = Label.new()
	healthValue.name = "HealthValue"
	healthValue.custom_minimum_size = Vector2(20, 16)
	healthValue.add_theme_font_size_override("font_size", 10)

	values.add_child(healthValue)
	
	spacer.size.y = spriteBox.size.y
	
	
func setCombatant(combatant : Combatant):
	self.registeredCombatant = combatant


func updateCharacter():
		
	healthPoints.max_value = registeredCombatant.max_health
	healthPoints.value = registeredCombatant.current_health
	healthValue.text = str(registeredCombatant.current_health)
	
	nameLabel.text = registeredCombatant.characterName
	var sprt : Sprite2D = registeredCombatant.find_child("Sprite2D")
	spriteImage.texture = sprt.texture
	
	spacer.size.y = spriteBox.size.y

## *Signal Function*
## Emits from battle after target selection phase
func toggleVisibility(visibility : bool):
	self.visible = visibility
