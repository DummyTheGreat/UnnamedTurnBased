extends Path2D

signal endReactionWindow()
signal initiateCombatExecution(timeSummation : float)

## *Signal Function*
## Emitted by battle.gd during the CombatStart state
func addFollowers(moveList : Array) -> void:
	var timeSummation : float = 0
	for move in moveList:
		timeSummation += move.reactionTime
		var follower = ReactionPathFollower.new(move.attackVariant, timeSummation)
		self.add_child(follower)
		child_order_changed.connect(handleFollowerRemoval)
	initiateCombatExecution.emit(timeSummation)

## *Signal Function*
## Emitted by self when a child is added or lost
func handleFollowerRemoval() -> void:
	if get_child_count() == 2:
		endReactionWindow.emit()

func _ready() -> void:
	var battle = get_parent().get_parent().get_parent().get_parent().get_parent()
	endReactionWindow.connect(battle.endCombatExecutionState)
	initiateCombatExecution.connect(battle.beginCombatExecutionState)
	
	
