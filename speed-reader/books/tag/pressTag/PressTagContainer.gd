extends MarginContainer

class_name PressTagContainer

@onready var _reference_rect : ReferenceRect = $ReferenceRect
@onready var _icon_rect : TextureRect = $MarginContainer/HBoxContainer/IconRect
@onready var _tag_container : TagContainer = $MarginContainer/HBoxContainer/Tag
@onready var _button : Button = $MarginContainer/Button

signal button_toggled(press_tag_container : PressTagContainer, toggled_on : bool)

func set_tag(tag : TagResource) -> void:
	_tag_container.set_tag(tag)

func get_tag() -> TagResource:
	return _tag_container.get_tag()

func set_pressed(pressed : bool) -> void:
	_button.button_pressed = pressed

func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_reference_rect.visible = true
		_icon_rect.visible = true
	else:
		_reference_rect.visible = false
		_icon_rect.visible = false
	button_toggled.emit(self, toggled_on)
