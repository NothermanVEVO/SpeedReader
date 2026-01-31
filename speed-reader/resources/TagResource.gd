extends Resource

class_name TagResource

@export var name : String ## UNIQUE
@export var background_color : Color
@export var foreground_color : Color

@warning_ignore("shadowed_variable")
func _init(name : String = "", background_color : Color = Color(0.5, 0.5, 0.5, 1.0), foreground_color : Color = Color()) -> void:
	self.name = name
	self.background_color = background_color
	self.foreground_color = foreground_color
