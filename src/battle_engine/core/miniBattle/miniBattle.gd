extends Node2D
class_name MiniBattle

var spawnEnemies : bool = false
var battleSequences : Array[Sequence]

@onready var floor : StaticBody2D = $Floor
@onready var leftWall : StaticBody2D = $LeftWall
@onready var rightWall : StaticBody2D = $RightWall
@onready var player : MiniPlayer = $Player
@onready var duration : Timer = $Duration

var vSize : Vector2


func _ready() -> void:
	## A solution to fixing pixelated texture weirdness
	RenderingServer.viewport_set_snap_2d_vertices_to_pixel(self.get_viewport(), true)
	# Set up bounds
	vSize = self.get_viewport_rect().size
	var fsh : RectangleShape2D = $Floor/CollisionShape2D.shape
	var fsp : Sprite2D = $Floor/Sprite2D
	floor.position = Vector2(vSize.x * 0.5, vSize.y * 0.9)
	fsh.size = Vector2(vSize.x, 20)
	fsp.scale = Vector2(vSize.x / fsp.texture.get_width(), 2)
	
	var lwsh : RectangleShape2D = $LeftWall/CollisionShape2D.shape
	var lwsp : Sprite2D = $LeftWall/Sprite2D
	leftWall.position = Vector2(vSize.x - 10, vSize.y * 0.5)
	lwsh.size = Vector2(20, vSize.y)
	lwsp.scale = Vector2(1, vSize.y / lwsp.texture.get_height())
	
	var rwsh : RectangleShape2D = $RightWall/CollisionShape2D.shape
	var rwsp : Sprite2D = $RightWall/Sprite2D
	rightWall.position = Vector2(0 + 10, vSize.y * 0.5)
	rwsh.size = Vector2(20, vSize.y)
	rwsp.scale = Vector2(1, vSize.y / rwsp.texture.get_height())
			
		
func start():
	# info to init battlesequence comes from the enemy's data
	for seq in battleSequences:
		var ats = BattleSequence.new(seq, player, vSize)
		self.add_child(ats)
		ats.play()
		
	duration.start()
	
	
