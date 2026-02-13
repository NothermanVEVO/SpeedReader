extends Resource

class_name SizePagesResource

@export var size : Vector2i
@export var start_pages_byte_pos : PackedInt64Array

@warning_ignore("shadowed_variable")
func _init(size : Vector2i = Vector2i.ZERO, start_pages_byte_pos : PackedInt64Array = PackedInt64Array()) -> void:
	self.size = size
	self.start_pages_byte_pos = start_pages_byte_pos
