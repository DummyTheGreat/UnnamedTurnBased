extends HBoxContainer
class_name ReactionUI

const reactorScene = preload("res://src/battle_engine/UI/Reactor.tscn")
var currentQTE : QTE = null

signal endReactionWindow()
signal initiateCombatExecution(timeSummation : float)
signal reactionEval(correctInput : bool, score : float, follower : QTE)

# How to init scenes
static func initNewQTE(
	isActive : bool, 
	index : int, 
	reactionTime : float, 
	inputAction : StringName
	) -> InputPressQTE:
	var newReactor: InputPressQTE = reactorScene.instantiate()
	newReactor.isActive = isActive
	newReactor.index = index
	newReactor.reactionTime = reactionTime
	newReactor.inputAction = inputAction
	return newReactor
	
static func initPatternQTE(
	scene : PackedScene,
	isActive : bool, 
	index : int, 
	reactionTime : float
	) -> PatternQTE:
	var newReactor: PatternQTE = scene.instantiate()
	newReactor.isActive = isActive
	newReactor.index = index
	newReactor.reactionTime = reactionTime
	return newReactor

## *Signal Function*
## Emitted by battle.gd during the CombatStart state
func addFollowers(moveList : Array[Move]) -> void:
	var timeSummation : float = 0
	var prevReactor : QTE = null
	var index = 1
	for move : Move in moveList:
		for action : Action in move.actionList:
			var reactor : QTE
			if action is CombatAction:
				reactor = initNewQTE(
					false if index > 1 else true, 
					index, 
					action.reactionTime,
					action.inputKeyName)
				reactor.submitReaction.connect(handlePressReaction)
			elif action is SkillAction:
				reactor = initPatternQTE(
					action.pattern,
					false if index > 1 else true,
					index,
					action.reactionTime
				)
				reactor.submitReaction.connect(handlePatternReaction)
			self.add_child(reactor)
			if prevReactor != null: # Create a shitty linked list chain
				prevReactor.nextEvent = reactor
			prevReactor = reactor
			
			if index == 1: #Init current reactor to start with
				currentQTE = reactor
			index += 1
			
	initiateCombatExecution.emit(timeSummation)
	currentQTE.startTimer()
	
func handlePressReaction(inputAction : StringName):
	if inputAction == currentQTE.inputAction:
		var score = currentQTE.getDifferenceScore()
		reactionEval.emit(true, score, currentQTE)
	else:
		reactionEval.emit(false, 0, currentQTE)
		
		# If it is a combo, cancel the move and go the the next move. If it's a move, cancel everything

func handlePatternReaction(ratio : float):
	reactionEval.emit(ratio >= 0.70, ratio, currentQTE)

	
## *Signal Function*
## Emitted by self when a child is added or lost
func handleFollowerRemoval() -> void:
	if self.get_child_count() == 0:
		endReactionWindow.emit()
		
func startNextReaction():
	var oldReactor = currentQTE
	currentQTE = currentQTE.nextEvent
	self.remove_child(oldReactor)
	oldReactor.end()
	if currentQTE != null:
		currentQTE.startTimer()
		
func skipNextReaction() -> QTE:
	var oldReactor = currentQTE
	currentQTE = currentQTE.nextEvent
	self.remove_child(oldReactor)
	oldReactor.end()
	return currentQTE

func _ready() -> void:
	var battle = self.owner
	endReactionWindow.connect(battle.endCombatExecutionState)
	initiateCombatExecution.connect(battle.beginCombatExecutionState)
	reactionEval.connect(battle.processComboInput)
	self.child_order_changed.connect(handleFollowerRemoval)
