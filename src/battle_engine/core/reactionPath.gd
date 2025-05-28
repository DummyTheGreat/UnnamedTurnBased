extends Path2D

@onready var clickArea : Area2D = $ClickArea

signal endReactionWindow()
signal initiateCombatExecution(timeSummation : float)

var followers : Array[ReactionPathFollower] = []

## *Signal Function*
## Emitted by battle.gd during the CombatStart state
func addFollowers(moveList : Array[Move]) -> void:
	var timeSummation : float = 0
	var prevFollower : ReactionPathFollower = null
	var index = 1
	for move : Move in moveList:
		for action : CombatAction in move.actionList:
			var follower = ReactionPathFollower.new(action.inputKeyName, action.reactionTime, prevFollower, index)
			self.add_child(follower)
			prevFollower = follower
			index += 1
			followers.append(follower)
	initiateCombatExecution.emit(timeSummation)
	startNextReaction()

## *Signal Function*
## Emitted by self when a child is added or lost
func handleFollowerRemoval() -> void:
	if get_child_count() == 2 and followers.is_empty():
		endReactionWindow.emit()
		
func startNextReaction():
	if followers.is_empty():
		return
	var nextReaction : ReactionPathFollower = followers.pop_front()
	nextReaction.startTimer()

func _ready() -> void:
	var battle = self.owner
	endReactionWindow.connect(battle.endCombatExecutionState)
	initiateCombatExecution.connect(battle.beginCombatExecutionState)
	self.child_order_changed.connect(handleFollowerRemoval)
	#clickArea.area_exited.connect(self.owner.nextComboIndex)
	
	
