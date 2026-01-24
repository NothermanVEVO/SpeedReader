extends Node

enum Languages {ENGLISH = 0, SPANISH = 1, PORTUGUESE = 2, SYSTEM = 3, UNKNOW = 4}

signal changed_language(language : Languages)

var _current_language : Languages = Languages.SYSTEM

const SETTINGS_PATH : String = "user://settings.json"
const SAVE_PATH : String = "user://save.json"

func set_language(language : Languages) -> void:
	_current_language = language
	
	if _current_language == Languages.SYSTEM:
		_current_language = get_language_by_code(OS.get_locale_language())
		if _current_language == Languages.UNKNOW:
			_current_language = Languages.ENGLISH
	
	TranslationServer.set_locale(get_current_language_code())
	changed_language.emit(language)

func get_language() -> Languages:
	return _current_language

func get_current_language_code() -> String:
	var language_code : String = get_language_code(_current_language)
	
	if language_code.is_empty():
		language_code = "en"
	
	return language_code

func get_language_code(language : Languages) -> String:
	match language:
		Languages.ENGLISH:
			return "en"
		Languages.SPANISH:
			return "es"
		Languages.PORTUGUESE:
			return "pt"
		_:
			return ""

func get_language_by_code(code : String) -> Languages:
	match code:
		"en":
			return Languages.ENGLISH
		"es":
			return Languages.SPANISH
		"pt":
			return Languages.PORTUGUESE
		_:
			return Languages.UNKNOW

func _ready() -> void:
	get_window().close_requested.connect(_on_close_requested)
	
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings()
	
	_load_settings()

func _on_close_requested() -> void:
	save_settings()
	get_tree().quit()

func save_settings() -> void:
	var data := {
		"window_mode": DisplayServer.window_get_mode(),
		"window_resolution": {
			"x": DisplayServer.window_get_size().x,
			"y": DisplayServer.window_get_size().y
		},
		"language": _current_language,
		"theme": Global.get_theme_type(),
		"wpm": SpeedReader.get_words_per_minute(),
		"keep_displaying": TextContainer.can_keep_displaying()
	}

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		print("Erro ao ler settings")
		return

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		print("JSON inválido em settings.json")
		return

	var data : Dictionary = json.data

	if data.has("window_mode"):
		DisplayServer.window_set_mode(data["window_mode"])
	
	if data.has("window_resolution"):
		var window_size := Vector2i(data["window_resolution"]["x"], data["window_resolution"]["y"])
		DisplayServer.window_set_size(window_size)
		var screen := DisplayServer.window_get_current_screen()
		var screen_size := DisplayServer.screen_get_size(screen)

		var pos := (screen_size - window_size) / 2
		DisplayServer.window_set_position(pos)
	
	if data.has("language"):
		set_language(data["language"])
	
	if data.has("theme"):
		Global.set_theme(data["theme"])
	
	if data.has("wpm"):
		SpeedReader.set_wpm(data["wpm"])
	
	if data.has("keep_displaying"):
		TextContainer.set_keep_displaying(data["keep_displaying"])

func save_data(id: String, word_byte_pos: int) -> void:
	var data := get_save_data()
	data[id] = word_byte_pos

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func get_save_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		print("Erro ao ler settings")
		return {}

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		print("JSON inválido em settings.json")
		return {}

	return json.data

func get_word_byte_pos(id : String) -> int:
	var word_byte_pos : int = -1
	var data : Dictionary = get_save_data()
	if data.has(id):
		word_byte_pos = data[id]
	return word_byte_pos
