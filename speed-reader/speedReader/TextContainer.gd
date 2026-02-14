extends MarginContainer

class_name TextContainer

const _WHITE_THEME : Theme = preload("res://themes/white/speedReader/base_text_container_theme_white.tres")
const _DARK_THEME : Theme = preload("res://themes/dark/speedReader/base_text_container_theme_dark.tres")

@onready var _return_button : Button = $VBoxContainer/Top/FlowContainer/ReturnButton
@onready var _settings_button : Button = $VBoxContainer/Top/FlowContainer/Settings
@onready var _keep_displaying_button : CheckButton = $VBoxContainer/Top/FlowContainer/KeepDisplaying

@onready var _full_text : FullText = $VBoxContainer/MarginContainer/VBoxContainer/FullText
@onready var _player : Player = $"../Player"

const _BOOKS_SCENE : PackedScene = preload("res://books/Books.tscn")

static var _keep_displaying : bool = false

var _fade_tween : Tween

const _SETTINGS_WINDOW_SCENE : PackedScene = preload("res://windows/settingsWindow/SettingsWindow.tscn")
@onready var _settings_window : SettingsWindow = _SETTINGS_WINDOW_SCENE.instantiate()

func _ready() -> void:
	if Files.current_selected_book:
		_open_book.call_deferred()
	
	_player.play.connect(_is_playing)
	
	Global.changed_theme.connect(_changed_theme)
	
	add_child(_settings_window)
	
	Settings.changed_language.connect(_set_text_by_language)
	_set_text_by_language(Settings.get_language())
	
	_keep_displaying_button.button_pressed = _keep_displaying
	
	get_window().close_requested.connect(_on_close_requested)

func _set_text_by_language(_language : Settings.Languages) -> void:
	_return_button.text = tr("Return")
	_settings_button.text = tr("Settings")
	_keep_displaying_button.text = tr("Keep Displaying HUD")

func _changed_theme(_theme : Global.Themes) -> void:
	match _theme:
		Global.Themes.DARK:
			print("dark")
			theme = _DARK_THEME
		Global.Themes.WHITE:
			print("white")
			theme = _WHITE_THEME

func _reset() -> void:
	_full_text.set_full_text("")

func _open_book() -> void:
	Files.get_text_from_imported_book(Files.current_selected_book)

func _on_keep_displaying_toggled(toggled_on: bool) -> void:
	_keep_displaying = toggled_on

static func can_keep_displaying() -> bool:
	return _keep_displaying

static func set_keep_displaying(keep_displaying : bool) -> void:
	_keep_displaying = keep_displaying

func _is_playing(is_playing : bool) -> void:
	if _keep_displaying:
		return
	if is_playing:
		_fade_out()
	else:
		_fade_in()

func _fade_in(duration: float = 0.2) -> void:
	if _fade_tween:
		_fade_tween.kill()

	self.visible = true
	_player.visible = true

	self.modulate.a = 0.0
	_player.modulate.a = 0.0

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_OUT)

	_fade_tween.parallel().tween_property(
		self,
		"modulate:a",
		1.0,
		duration
	)

	_fade_tween.parallel().tween_property(
		_player,
		"modulate:a",
		1.0,
		duration
	)

func _fade_out(duration: float = 0.2) -> void:
	if _fade_tween:
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_IN)

	_fade_tween.parallel().tween_property(
		self,
		"modulate:a",
		0.0,
		duration
	)

	_fade_tween.parallel().tween_property(
		_player,
		"modulate:a",
		0.0,
		duration
	)

	_fade_tween.finished.connect(func ():
		self.visible = false
		_player.visible = false
	)

func _on_settings_pressed() -> void:
	if not _settings_window.visible:
		_settings_window.popup()

func can_reopen_file() -> bool:
	return Files.current_selected_book != null

func reopen_file() -> void:
	if not can_reopen_file():
		return
	_open_book()

func _on_close_requested() -> void:
	if not Files.current_selected_book:
		return
	
	save_last_word_in_book_position()

func save_last_word_in_book_position() -> void:
	Files.current_selected_book.last_word_byte_pos = _full_text.get_page_n_word_idx()
	Files.save_book(Files.current_selected_book)

func _on_return_button_pressed() -> void:
	save_last_word_in_book_position()
	get_tree().change_scene_to_packed(_BOOKS_SCENE)
