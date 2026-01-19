extends AcceptDialog

class_name InputDialog

var _line_edit := LineEdit.new()

signal text_confirmed(text : String)

func _ready() -> void:
	force_native = true
	add_child(_line_edit)
	size = Vector2(400, 50)
	confirmed.connect(_confirmed)
	_line_edit.text_submitted.connect(_line_edit_text_submitted)

func define_text(text : String) -> void:
	_line_edit.placeholder_text = text

func _line_edit_text_submitted(text : String) -> void:
	visible = false
	text_confirmed.emit(text)
	_line_edit.text = ""

func _confirmed() -> void:
	text_confirmed.emit(_line_edit.text)
	_line_edit.text = ""
