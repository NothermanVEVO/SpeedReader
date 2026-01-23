extends Window

class_name SettingsWindow

const _WHITE_THEME : Theme = preload("res://themes/white/base_settings_theme_white.tres")
const _DARK_THEME : Theme = preload("res://themes/dark/base_settings_theme_dark.tres")

@onready var _options_container : MarginContainer = $HBoxContainer/OptionsContainer

@onready var _background_color : ColorRect = $BackgroundColor

@onready var _options_item_list = $HBoxContainer/VBoxContainer/OptionsItemList

const _THEME_OPTION_SCENE : PackedScene = preload("res://windows/settingsWindow/options/ThemeOption.tscn")

var _last_option_control : Control

func _ready() -> void:
	Global.changed_theme.connect(_changed_theme)
	
	_changed_theme(Global.get_theme_type())

func _changed_theme(_theme : Global.Themes) -> void:
	match _theme:
		Global.Themes.DARK:
			theme = _DARK_THEME
			_background_color.color = Color(0, 0, 0, 1)
		Global.Themes.WHITE:
			theme = _WHITE_THEME
			_background_color.color = Color(1, 1, 1, 1)

func _on_options_item_selected(index: int) -> void:
	if _last_option_control:
		_options_container.remove_child(_last_option_control)
		_last_option_control.queue_free()
	
	match _options_item_list.get_item_text(index):
		"Tema":
			_last_option_control = _THEME_OPTION_SCENE.instantiate()
			_options_container.add_child(_last_option_control)
		_:
			pass

func _on_close_requested() -> void:
	hide()
