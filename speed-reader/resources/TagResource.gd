extends Resource

class_name TagResource

enum SelectType {UNSELECTED, SELECTED_INCLUDE, SELECTED_EXCLUDE}

@export var name : String ## UNIQUE
@export var background_color : Color
@export var foreground_color : Color

var select_type : SelectType = SelectType.UNSELECTED

@warning_ignore("shadowed_variable")
func _init(name : String = "", background_color : Color = Color(), foreground_color : Color = Color()) -> void:
	self.name = name
	self.background_color = background_color
	self.foreground_color = foreground_color
