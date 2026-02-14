extends MarginContainer

class_name Player

const _WHITE_THEME : Theme = preload("res://themes/white/speedReader/base_player_theme_white.tres")
const _DARK_THEME : Theme = preload("res://themes/dark/speedReader/base_player_theme_dark.tres")

const _WHITE_GO_BACKWARD_ICON : CompressedTexture2D = preload("res://assets/dark theme/white_skip_back_button.png")
const _WHITE_GO_FORWARD_ICON : CompressedTexture2D = preload("res://assets/dark theme/white_skip_forward_button.png")

const _DARK_GO_BACKWARD_ICON : CompressedTexture2D = preload("res://assets/white theme/dark_skip_back_button.png")
const _DARK_GO_FORWARD_ICON : CompressedTexture2D = preload("res://assets/white theme/dark_skip_forward_button.png")

const _WHITE_PAUSE_ICON : CompressedTexture2D = preload("res://assets/dark theme/white_pause_button.png")
const _WHITE_PLAY_ICON : CompressedTexture2D = preload("res://assets/dark theme/white_play_button.png")

const _DARK_PAUSE_ICON : CompressedTexture2D = preload("res://assets/white theme/dark_pause_button.png")
const _DARK_PLAY_ICON : CompressedTexture2D = preload("res://assets/white theme/dark_play_button.png")

var _current_pause_icon : CompressedTexture2D
var _current_play_icon : CompressedTexture2D

@onready var _book_name_rich_text_label : RichTextLabel = $VBoxContainer/BookNameRichTextLabel

@onready var _go_backward_button : Button = $VBoxContainer/FlowContainer/HBoxContainer/Backwards
@onready var _play_button : Button = $VBoxContainer/FlowContainer/HBoxContainer/Play
@onready var _go_forward_button : Button = $VBoxContainer/FlowContainer/HBoxContainer/Forwards

@onready var _wpm_spin_box : SpinBox = $VBoxContainer/FlowContainer/WordsPerMinute/WPMSpinBox
@onready var _wpm_hslider : HSlider = $VBoxContainer/FlowContainer/WordsPerMinute/WPMHSlider

@onready var _wpm_text : RichTextLabel = $VBoxContainer/FlowContainer/WordsPerMinute/WPMText

signal go_backward
signal play(can_play : bool)
signal go_forward
signal wpm_changed(wpm : int)

var _is_paused : bool = true

func _ready() -> void:
	_wpm_spin_box.min_value = SpeedReader.MIN_WORDS_PER_MINUTE
	_wpm_spin_box.max_value = SpeedReader.MAX_WORDS_PER_MINUTE
	
	_wpm_hslider.min_value = SpeedReader.MIN_WORDS_PER_MINUTE
	_wpm_hslider.max_value = SpeedReader.MAX_WORDS_PER_MINUTE
	
	_wpm_spin_box.get_line_edit().text_submitted.connect(_remove_wpm_line_edit_focus)
	
	set_paused(true)
	
	Global.changed_theme.connect(_changed_theme)
	
	Settings.changed_language.connect(_set_text_by_language)
	_set_text_by_language(Settings.get_language())
	
	if Files.current_selected_book:
		_book_name_rich_text_label.text = Files.current_selected_book.name

func _set_text_by_language(_language : Settings.Languages) -> void:
	_wpm_text.text = tr("Words Per Minute") + " (" + tr("WPM") + ")"
	_wpm_spin_box.suffix = tr("WPM")

func _changed_theme(_theme : Global.Themes) -> void:
	var current_theme : Theme
	match _theme:
		Global.Themes.DARK:
			current_theme = _DARK_THEME
			_current_pause_icon = _WHITE_PAUSE_ICON
			_current_play_icon = _WHITE_PLAY_ICON
			
			_go_backward_button.icon = _WHITE_GO_BACKWARD_ICON
			
			_go_forward_button.icon = _WHITE_GO_FORWARD_ICON
		Global.Themes.WHITE:
			current_theme = _WHITE_THEME
			_current_pause_icon = _DARK_PAUSE_ICON
			_current_play_icon = _DARK_PLAY_ICON
			
			_go_backward_button.icon = _DARK_GO_BACKWARD_ICON
			
			_go_forward_button.icon = _DARK_GO_FORWARD_ICON
	
	theme = current_theme
	
	if _is_paused:
		_play_button.icon = _current_play_icon
	else:
		_play_button.icon = _current_pause_icon

func _on_backwards_pressed() -> void:
	if not _is_paused:
		set_paused(true)
	go_backward.emit()

func _on_play_pressed() -> void:
	set_paused(not _is_paused)

func set_paused(is_paused : bool) -> void:
	if is_paused == _is_paused:
		return
	_is_paused = is_paused
	if is_paused:
		_play_button.icon = _current_play_icon
	else:
		_play_button.icon = _current_pause_icon
	play.emit(not _is_paused)

func set_wpm(wpm : float, display_particle : bool = true) -> void:
	if display_particle:
		if _wpm_spin_box.value < wpm:
			add_wpm_particle(WPMParticles.Types.PLUS)
		elif _wpm_spin_box.value > wpm:
			add_wpm_particle(WPMParticles.Types.MINUS)
	_wpm_spin_box.value = wpm
	_wpm_hslider.value = wpm

func _on_forwards_pressed() -> void:
	if not _is_paused:
		set_paused(true)
	go_forward.emit()

func add_wpm_particle(type : WPMParticles.Types) -> void:
	var wpm_particle := WPMParticles.new(type)
	add_child(wpm_particle)
	wpm_particle.global_position = _wpm_spin_box.global_position
	wpm_particle.global_position.x += _wpm_spin_box.size.x / 2

func _on_wpm_spin_box_value_changed(value: float) -> void:
	if not _is_paused:
		set_paused(true)
	_wpm_hslider.value = value
	wpm_changed.emit(value)

func _on_wpm_hslider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		_wpm_spin_box.value = _wpm_hslider.value
		wpm_changed.emit(_wpm_hslider.value)

func _on_wpm_hslider_value_changed(value: float) -> void:
	if not _is_paused:
		set_paused(true)
	_wpm_spin_box.value = _wpm_hslider.value

func is_in_focus() -> bool:
	return _wpm_spin_box.get_line_edit().has_focus()

func _remove_wpm_line_edit_focus(_new_text: String) -> void:
	await get_tree().create_timer(0.1).timeout
	_wpm_spin_box.get_line_edit().release_focus()
