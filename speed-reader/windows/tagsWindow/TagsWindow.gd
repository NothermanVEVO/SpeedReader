extends Window

@onready var _new_tag_window : Window = $NewTagWindow

func _on_new_button_pressed() -> void:
	_new_tag_window.popup_centered()

func _on_close_requested() -> void:
	visible = false
