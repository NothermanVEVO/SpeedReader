extends MarginContainer

class_name Player

const _PAUSE_ICON : CompressedTexture2D = preload("res://assets/white_pause_button.png")
const _PLAY_ICON : CompressedTexture2D = preload("res://assets/white_play_button.png")

@onready var _play_button : Button = $HBoxContainer/Play

@onready var _wpm_spin_box : SpinBox = $HBoxContainer/WordsPerMinute/WPMSpinBox
@onready var _wpm_hslider : HSlider = $HBoxContainer/WordsPerMinute/WPMHSlider

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
	
	set_paused(true)

func _on_backwards_pressed() -> void:
	set_paused(true)
	go_backward.emit()

func _on_play_pressed() -> void:
	set_paused(not _is_paused)

func set_paused(is_paused : bool) -> void:
	_is_paused = is_paused
	if is_paused:
		_play_button.icon = _PLAY_ICON
	else:
		_play_button.icon = _PAUSE_ICON
	play.emit(not _is_paused)

func set_wpm(wpm : int) -> void:
	_wpm_spin_box.value = wpm
	_wpm_hslider.value = wpm

func _on_forwards_pressed() -> void:
	set_paused(true)
	go_forward.emit()

func _on_wpm_spin_box_value_changed(value: float) -> void:
	set_paused(true)
	_wpm_hslider.value = value
	wpm_changed.emit(value)

func _on_wpm_hslider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		_wpm_spin_box.value = _wpm_hslider.value
		wpm_changed.emit(_wpm_hslider.value)

func _on_wpm_hslider_value_changed(value: float) -> void:
	set_paused(true)
	_wpm_spin_box.value = _wpm_hslider.value
