class_name CircularDoubleLinkedList

## Internal Class for holding Linked List data
class ListNode:
	
	var data : Combatant
	var next : ListNode
	var prev : ListNode
	
	func _init(data : Combatant, next: ListNode = null, prev : ListNode = null) -> void:
		self.data = data
		self.next = next
		self.prev = prev
		
## Circular double linked list, currently only for combatants
var head : ListNode
var tail : ListNode
var pointer : ListNode
var size : int

func _init() -> void:
	self.size = 0

# Attach to end of the circular list
func append(data : Combatant) -> void:
	if head == null:
		head = ListNode.new(data)
		head.next = head
		head.prev = head
		tail = head
		pointer = head
	else:
		var newNode = ListNode.new(data, head, tail)
		tail.next = newNode
		head.prev = newNode
		tail = newNode
	size += 1
		
func setPointer(data : Combatant) -> ListNode:
	if head.data == data:
		return head
	
	pointer = head.next
	while pointer != head:
		if pointer.data == data:
			return pointer
		pointer = head.next
	
	return null
		
		
func insertAfterPointer(data : Combatant) -> bool:
	if pointer == null:
		return false
		
	if (size == 1 and head.data == pointer.data) or tail.data == pointer.data:
		self.append(data)
		return true
		
	var temp = pointer.next
	var newNode = ListNode.new(data, temp, pointer)
	pointer.next = newNode
	temp.prev = newNode
	size += 1
	
	return true
	
	
func remove(data : Combatant) -> bool:
	if size == 1:
		head = null
		tail = null
		size = 0
		return true

	self.setPointer(data)
	if pointer != null:
		pointer.prev.next = pointer.next
		pointer.next.prev = pointer.prev
		
		if pointer == head:
			head = head.next
		if pointer == tail:
			tail = tail.prev
			
		pointer = head
		size -= 1
		return true
		
	return false
