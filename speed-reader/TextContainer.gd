extends MarginContainer

class_name TextContainer

@onready var _full_text : FullText = $VBoxContainer/FullText
@onready var _text_edit : TextEdit = $VBoxContainer/TextEdit

@onready var _edit_button : Button = $VBoxContainer/Top/HBoxContainer/Edit

var _is_editing : bool = false

signal editing_text(is_editing : bool)

func is_editing() -> bool:
	return _is_editing

func get_text() -> String:
	return _text_edit.text

func _on_edit_toggled(toggled_on: bool) -> void:
	_is_editing = toggled_on
	editing_text.emit(_is_editing)
	_edit_button.release_focus()
	if toggled_on:
		_edit_button.text = "Parar edição"
		_full_text.visible = false
		_text_edit.visible = true
		_text_edit.text = _full_text.get_full_text()
		_full_text.disable_pages()
	else:
		_edit_button.text = "Editar"
		_full_text.visible = true
		_text_edit.visible = false
		_full_text.set_full_text(_text_edit.text)
