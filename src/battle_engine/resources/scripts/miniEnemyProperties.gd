extends MiniProperties
class_name MiniEnemyProperties

@export var AIScript : Script

func _init(logicScript : Script = null) -> void:
	self.AIScript = logicScript
