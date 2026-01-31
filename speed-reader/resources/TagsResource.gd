extends Resource

class_name TagsResource

var tags : Array[TagResource]

@warning_ignore("shadowed_variable")
func _init(tags : Array[TagResource] = []) -> void:
	self.tags = tags
