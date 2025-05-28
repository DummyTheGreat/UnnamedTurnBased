class_name LinkedList

## Internal Class for holding Linked List data
class ListNode:
	
	var data : Resource
	var next : ListNode
	
	func _init(data : Resource, next: ListNode = null) -> void:
		self.data = data
		self.next = next
		
## Circular double linked list, currently only for combatants
var head : ListNode
var pointer : ListNode
var size : int

func _init() -> void:
	self.size = 0

# Attach to end of the circular list
func append(data : Resource) -> void:
	
	if head == null:
		head = ListNode.new(data)
		return
		
	var node = head
	while node.next != null:
		node = node.next
		
	node.next = ListNode.new(data)
