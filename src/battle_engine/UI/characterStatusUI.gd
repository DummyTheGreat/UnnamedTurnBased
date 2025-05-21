extends HBoxContainer
class_name CharacterStatusUI

@onready var healthBar : ProgressBar = $Bars/HealthPoints
@onready var comboBar : ProgressBar = $Bars/ComboPoints
@onready var skillBar : ProgressBar = $Bars/SkillPoints
@onready var nameLabel : Label = $SpriteBox/Name
@onready var imageSlot : TextureRect = $SpriteBox/SpriteImage

## *Signal Function*
## Emits from battle upon a new character turn
func updateCharacter(combatant: Combatant):
	
	healthBar.max_value = combatant.max_health
	healthBar.value = combatant.current_health
	## TODO: Change when actual values are implemented
	comboBar.max_value = 10
	comboBar.value = 10
	skillBar.max_value = 10
	skillBar.value = 10
	
	nameLabel.text = combatant.characterName
	var sprt : Sprite2D = combatant.find_child("Sprite2D")
	imageSlot.texture = sprt.texture

## *Signal Function*
## Emits from battle after target selection phase
func toggleVisibility(visibility : bool):
	self.visible = visibility
