extends MarginContainer

class_name ToggleListContainer

var _max_size_x : float = 200.0

@onready var _background_color_rect : ColorRect = $BackgroundColorRect
@onready var _name_rich_text_label : RichTextLabel = $MarginContainer/HBoxContainer/NameScrollContainer/NameRichTextLabel
@onready var _name_scroll_container : ScrollContainer = $MarginContainer/HBoxContainer/NameScrollContainer

@onready var _button : Button = $Button
@onready var _check_box : CheckBox = $MarginContainer/HBoxContainer/CheckBox

@onready var _margin_container : MarginContainer = $MarginContainer

var _list : ListResource

signal toggled(toggle_list_container : ToggleListContainer, toggled_on : bool)

func _ready() -> void:
	_name_rich_text_label.resized.connect(_resize_text)

func set_list(list : ListResource) -> void:
	_list = list
	
	if not _list:
		return
	
	_background_color_rect.color = _list.background_color
	_name_rich_text_label.add_theme_color_override("default_color", _list.foreground_color)
	_name_rich_text_label.text = _list.name
	#await _name_rich_text_label.resized
	#_resize_text()

func get_list() -> ListResource:
	return _list

func _resize_text() -> void:
	_name_scroll_container.custom_minimum_size.x = _name_rich_text_label.size.x if _name_rich_text_label.size.x <= _max_size_x else _max_size_x
	
	if _name_scroll_container.custom_minimum_size.x < _name_rich_text_label.size.x:
		_name_scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		_name_scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_pressed(pressed : bool) -> void:
	_button.button_pressed = pressed

func set_size_flag_horizontal(size_flag : SizeFlags) -> void:
	_margin_container.size_flags_horizontal = size_flag

func set_max_size_x(max_size_x : float) -> void:
	_max_size_x = max_size_x
	_resize_text()

func get_max_size_x() -> float:
	return _max_size_x

func _on_button_toggled(toggled_on: bool) -> void:
	if not _list:
		return
	toggled.emit(self, toggled_on)
	_check_box.button_pressed = toggled_on
