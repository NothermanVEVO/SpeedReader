extends MarginContainer

class_name ListContainer

static var _max_size_x : float = 200.0

@onready var _rich_text_label : RichTextLabel = $MarginContainer/HBoxContainer/NameScrollContainer/RichTextLabel
@onready var _name_scroll_container : ScrollContainer = $MarginContainer/HBoxContainer/NameScrollContainer

func _ready() -> void:
	_resize_text()
	GlobalSignals.changed_list_max_size_x.connect(_resize_text)

func set_text(text : String) -> void:
	_rich_text_label.text = text
	_resize_text()

func _resize_text() -> void:
	_name_scroll_container.custom_minimum_size.x = _rich_text_label.size.x if _rich_text_label.size.x <= _max_size_x else _max_size_x
	_name_scroll_container.custom_minimum_size.y = _rich_text_label.size.y + 5

static func set_max_size_x(max_size_x : float) -> void:
	_max_size_x = max_size_x
	GlobalSignals.changed_list_max_size_x.emit()

static func get_max_size_x() -> float:
	return _max_size_x
