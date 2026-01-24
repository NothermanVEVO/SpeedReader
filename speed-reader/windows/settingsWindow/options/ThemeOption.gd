extends MarginContainer

@onready var _theme_title : RichTextLabel = $VBoxContainer/ThemeTitle
@onready var _theme_option_button : OptionButton = $VBoxContainer/ThemeOptionButton

func _ready() -> void:
	_theme_option_button.selected = Global.get_theme_type()
	
	Settings.changed_language.connect(_set_text_by_language)
	_set_text_by_language(Settings.get_language())

func _set_text_by_language(_language : Settings.Languages) -> void:
	_theme_title.text = tr("Theme") + ":"
	_theme_option_button.set_item_text(0, tr("Dark"))
	_theme_option_button.set_item_text(1, tr("White"))

func _on_theme_option_button_item_selected(index: int) -> void:
	var id := _theme_option_button.get_item_id(index)
	Global.set_theme(id)
