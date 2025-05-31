extends Control
class_name ReactionUI

const reactorScene = preload("res://src/battle_engine/UI/Reactor.tscn")
var currentReactor : Reactor = null

signal endReactionWindow()
signal initiateCombatExecution(timeSummation : float)
signal reactionEval(correctInput : bool, score : float)

# How to init scenes
static func initNewReactor(
	isActive : bool, 
	index : int, 
	reactionTime : float, 
	inputAction : StringName
	) -> Reactor:
	var newReactor: Reactor = reactorScene.instantiate()
	newReactor.isActive = isActive
	newReactor.index = index
	newReactor.reactionTime = reactionTime
	newReactor.inputAction = inputAction
	return newReactor

## *Signal Function*
## Emitted by battle.gd during the CombatStart state
func addFollowers(moveList : Array[Move]) -> void:
	var timeSummation : float = 0
	var prevReactor : Reactor = null
	var index = 1
	for move : Move in moveList:
		for action : CombatAction in move.actionList:
			var reactor = initNewReactor(
				false if index > 1 else true, 
				index, 
				action.reactionTime,
				action.inputKeyName)
				
			self.add_child(reactor)
			
			if prevReactor != null: # Create a shitty linked list chain
				prevReactor.nextReactor = reactor
			prevReactor = reactor
			
			if index == 1: #Init current reactor to start with
				currentReactor = reactor
			index += 1
			
	initiateCombatExecution.emit(timeSummation)
	currentReactor.startTimer()
	pass
	
func handleReaction(inputAction : StringName):
	if inputAction == currentReactor.inputAction:
		var score = currentReactor.getDifferenceScore()
		reactionEval.emit(true, score, currentReactor.getIndex())
	else:
		pass
		# If it is a combo, cancel the move and go the the next move. If it's a move, cancel everything
	
## *Signal Function*
## Emitted by self when a child is added or lost
func handleFollowerRemoval() -> void:
	if self.get_child_count() == 2:
		endReactionWindow.emit()
		
func startNextReaction():
	currentReactor = currentReactor.nextReactor
	if currentReactor != null:
		currentReactor.startTimer()

func _ready() -> void:
	var battle = self.owner
	endReactionWindow.connect(battle.endCombatExecutionState)
	initiateCombatExecution.connect(battle.beginCombatExecutionState)
	reactionEval.connect(battle.processComboInput)
	self.child_order_changed.connect(handleFollowerRemoval)
	battle.reactionTriggered.connect(handleReaction)
