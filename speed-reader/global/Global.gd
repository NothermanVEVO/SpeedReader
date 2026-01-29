extends Node

enum Themes {DARK = 0, WHITE = 1}

var _theme : Themes

signal changed_theme(theme : Themes)

var _current_theme : Theme

func _ready() -> void:
	changed_theme.emit.call_deferred(_theme)

func split_text_by_space(text : String) -> PackedStringArray:
	if is_only_whitespace(text):
		return []
	
	var regex := RegEx.new()
	regex.compile("\\s+")
	text = regex.sub(text, " ", true)
	text = text.strip_edges()
	var s = text.split(" ")
	return s

func is_whitespace(c: String) -> bool:
	return c == " " or c == "\n" or c == "\t" or c == "\r"

func is_only_whitespace(text : String) -> bool:
	return text.strip_edges().is_empty()

func set_theme(theme : Themes) -> void:
	if theme != _theme:
		_theme = theme
		changed_theme.emit.call_deferred(_theme)

func get_theme_type() -> Themes:
	return _theme

func get_current_theme() -> Theme:
	return _current_theme

func get_theme_text_color() -> Color:
	match _theme:
		Themes.DARK:
			return Color.WHITE
		Themes.WHITE:
			return Color.BLACK
		_:
			return Color.WHITE

func get_UUID() -> String:
	var rng := RandomNumberGenerator.new()
	
	var values = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
	var begin := ""
	var middle := ""
	var end := ""
	
	for i in range(12):
		begin += values.substr(rng.randi_range(0, values.length() - 1), 1)
	for i in range(10):
		middle += values.substr(rng.randi_range(0, values.length() - 1), 1)
	for i in range(16):
		end += values.substr(rng.randi_range(0, values.length() - 1), 1)
	
	return begin + "-" + middle + "-" + end
