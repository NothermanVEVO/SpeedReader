extends Resource

class_name SizePagesResource

@export var size : String
@export var pages : int

@warning_ignore("shadowed_variable")
func _init(size : String = "", pages : int = 0) -> void:
	self.size = size
	self.pages = pages
