extends Node2D
class_name MiniBattle

var spawnEnemies : bool = false
var battleSequences : Array[Sequence]

@onready var floor : StaticBody2D = $Floor
@onready var leftWall : StaticBody2D = $LeftWall
@onready var rightWall : StaticBody2D = $RightWall
@onready var player : MiniPlayer = $Player
@onready var duration : Timer = $Duration
@onready var miniCamera : Camera2D = $Player/MiniCamera

var vSize : Vector2


func _ready() -> void:
	## A solution to fixing pixelated texture weirdness
	RenderingServer.viewport_set_snap_2d_vertices_to_pixel(self.get_viewport(), true)
	# Set up bounds
	vSize = self.get_viewport_rect().size
		
		
func initialize(selectedSequence : Sequence, timeoutFunc : Callable):
	## TODO: CHANGE DECISION AI TO SELECT A SEQUENCE 
	self.battleSequences.append(selectedSequence)
	## TODO: Multiple enemies should act at once, duration is maximum of all
	#miniBattle.duration = max(actingCombatants.selectedSequence.duration)
	self.duration.wait_time = selectedSequence.duration
	self.duration.timeout.connect(timeoutFunc)
	player.toggleCamera()
	
	var layout = load("res://src/battle_engine/core/miniBattle/platforming/layouts/BasePlatformingLayout.tscn").instantiate()
	print(layout)
	self.add_child(layout)

func start():
	# info to init battlesequence comes from the enemy's data
	for seq in battleSequences:
		var ats = BattleSequence.new(seq, player, vSize)
		self.add_child(ats)
		ats.play()
		
	duration.start()
	
	
