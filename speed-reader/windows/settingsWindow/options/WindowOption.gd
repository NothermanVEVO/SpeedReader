extends MarginContainer

@onready var _mode_title : RichTextLabel = $VBoxContainer/ModeTitle
@onready var _mode_option_button : OptionButton = $VBoxContainer/ModeOptionButton

@onready var _resolution_title : RichTextLabel = $VBoxContainer/ResolutionTitle
@onready var _resolution_option_button : OptionButton = $VBoxContainer/ResolutionOptionButton

static var _resolutions : Array[Vector2i]

func _ready() -> void:
	if not _resolutions:
		_resolutions = get_available_resolutions()

	_resolution_option_button.clear()
	for i in range(_resolutions.size()):
		var r := _resolutions[i]
		_resolution_option_button.add_item("%dx%d" % [r.x, r.y], i)
	
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_MAXIMIZED:
			_mode_option_button.selected = 0
			_resolution_option_button.disabled = false
			var current_size: Vector2i = DisplayServer.window_get_size()
			var idx := _resolutions.find(current_size)

			if idx != -1:
				_resolution_option_button.select(idx)
			else:
				_resolution_option_button.select(0)
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			_mode_option_button.selected = 1
			_resolution_option_button.disabled = true
	
	Settings.changed_language.connect(_set_text_by_language)
	_set_text_by_language(Settings.get_language())

func _set_text_by_language(_language : Settings.Languages) -> void:
	_mode_title.text = tr("Mode") + ":"
	_resolution_title.text = tr("Resolution") + ":"
	
	_mode_option_button.set_item_text(0, tr("Window"))
	_mode_option_button.set_item_text(1, tr("Fullscreen"))

func get_available_resolutions() -> Array[Vector2i]:
	var screen := DisplayServer.window_get_current_screen()
	var monitor_size: Vector2i = DisplayServer.screen_get_size(screen)

	var VGA := Vector2i(640, 480)

	var standard := [
		Vector2i(7680, 4320), # 8K
		Vector2i(5120, 2880), # 5K
		Vector2i(3840, 2160), # 4K
		Vector2i(2560, 1440), # 1440p
		Vector2i(1920, 1080), # Full HD
		Vector2i(1600, 900),  # HD+
		Vector2i(1366, 768),  # Notebook comum
		Vector2i(1280, 720),  # HD
		Vector2i(1152, 648),  # GODOT
		Vector2i(1024, 600),  # WSVGA
		Vector2i(1024, 576),  # 16:9 menor
		Vector2i(854, 480),   # WVGA
		Vector2i(640, 480),   # VGA
	]

	var result: Array[Vector2i] = []

	if monitor_size.x < VGA.x or monitor_size.y < VGA.y:
		return [monitor_size]

	result.append(monitor_size)
	
	for r in standard:
		if r == monitor_size:
			continue

		if r.x <= monitor_size.x and r.y <= monitor_size.y:
			result.append(r)

	return result

func _on_resolution_option_button_item_selected(index: int) -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(_resolutions[index])
	
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var window_size := DisplayServer.window_get_size()

	var pos := (screen_size - window_size) / 2
	DisplayServer.window_set_position(pos)

func _on_mode_option_button_item_selected(index: int) -> void:
	var window_text : String = tr("Window")
	var fullscreen_text : String = tr("Fullscreen")
	
	match _mode_option_button.get_item_text(index):
		window_text:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_resolution_option_button.disabled = false
			
			var screen := DisplayServer.window_get_current_screen()
			var screen_size := DisplayServer.screen_get_size(screen)
			var window_size := DisplayServer.window_get_size()

			var pos := (screen_size - window_size) / 2
			DisplayServer.window_set_position(pos)
		fullscreen_text:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			_resolution_option_button.disabled = true
