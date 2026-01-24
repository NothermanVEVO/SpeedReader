extends Window

class_name SettingsWindow

const _WHITE_THEME : Theme = preload("res://themes/white/base_settings_theme_white.tres")
const _DARK_THEME : Theme = preload("res://themes/dark/base_settings_theme_dark.tres")

@onready var _options_container : MarginContainer = $HBoxContainer/OptionsContainer

@onready var _background_color : ColorRect = $BackgroundColor

@onready var _general_text : RichTextLabel = $HBoxContainer/VBoxContainer/GeneralText
@onready var _options_item_list = $HBoxContainer/VBoxContainer/OptionsItemList

const _WINDOW_OPTION_SCENE : PackedScene = preload("res://windows/settingsWindow/options/WindowOption.tscn")
const _THEME_OPTION_SCENE : PackedScene = preload("res://windows/settingsWindow/options/ThemeOption.tscn")
const _LANGUAGE_OPTION_SCENE : PackedScene = preload("res://windows/settingsWindow/options/LanguageOption.tscn")

var _last_option_control : Control

func _ready() -> void:
	Global.changed_theme.connect(_changed_theme)
	
	_changed_theme(Global.get_theme_type())
	
	Settings.changed_language.connect(_set_text_by_language)
	_set_text_by_language(Settings.get_language())

func _set_text_by_language(_language : Settings.Languages) -> void:
	title = tr("Settings")
	_general_text.text = tr("General")
	_options_item_list.set_item_text(0, tr("Window"))
	_options_item_list.set_item_text(1, tr("Theme"))
	_options_item_list.set_item_text(2, tr("Language"))
	_options_item_list.set_item_text(3, tr("Font"))

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
	
	var window_text : String = tr("Window")
	var theme_text : String = tr("Theme")
	var language_text : String = tr("Language")
	
	match _options_item_list.get_item_text(index):
		window_text:
			_last_option_control = _WINDOW_OPTION_SCENE.instantiate()
		theme_text:
			_last_option_control = _THEME_OPTION_SCENE.instantiate()
		language_text:
			_last_option_control = _LANGUAGE_OPTION_SCENE.instantiate()
		_:
			pass
	
	if _last_option_control:
		_options_container.add_child(_last_option_control)

func _on_close_requested() -> void:
	hide()

func _on_about_to_popup() -> void:
	_set_text_by_language(Settings.get_language())
