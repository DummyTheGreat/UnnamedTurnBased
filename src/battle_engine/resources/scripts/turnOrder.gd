extends Resource
class_name TurnOrder

## A TurnOrder is a custom data object that correlates with a combatant. It's 
## used for sorting the speeds of each combatant and determining turn order

var combatant : CharacterStats ## Combatant
var combatantLabel : Label ## Combatant's Label in turnorder UI
var tempAV : int = 0

func _init(character : CharacterStats, label : Label) -> void:
	combatant = character
	combatantLabel = label
	
func getLabel() -> Label:
	return combatantLabel
	
func getCombatant() -> CharacterStats:
	return combatant
	
func setTempAV(aV : int) -> void:
	tempAV = aV
func getTempAV() -> int:
	return tempAV
