extends Resource

class_name ListsResource

@export var lists : Array[ListResource]

@warning_ignore("shadowed_variable")
func _init(lists : Array[ListResource] = []) -> void:
	self.lists = lists
