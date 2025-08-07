extends Resource
class_name SequenceItem

# Intended to hold projectile properties, AOE properties, 
@export var data : Array[MiniProperties]
@export var nextBufferTime : float

func _init(
	data : Array[MiniProperties] = [], 
	nextBufferTime : float = 0.0) -> void:
	self.data = data
	self.nextBufferTime = nextBufferTime
	
