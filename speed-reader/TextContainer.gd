extends MarginContainer

class_name TextContainer

enum File {OPEN = 0, IMPORT = 1, OPEN_DIRECTORY = 2}

const _WHITE_THEME : Theme = preload("res://themes/white/base_text_container_theme_white.tres")
const _DARK_THEME : Theme = preload("res://themes/dark/base_text_container_theme_dark.tres")

@onready var _file_menu_button : MenuButton = $VBoxContainer/Top/FlowContainer/File
@onready var _settings_button : Button = $VBoxContainer/Top/FlowContainer/Settings
@onready var _keep_displaying_button : CheckButton = $VBoxContainer/Top/FlowContainer/KeepDisplaying

@onready var _file_dialog : FileDialog = $FileDialog
@onready var _accept_dialog : AcceptDialog = $AcceptDialog
@onready var _input_dialog : InputDialog = $InputDialog

@onready var _full_text : FullText = $VBoxContainer/MarginContainer/VBoxContainer/FullText
@onready var _player : Player = $"../Player"

var _last_file_dialog_request : File

var _last_import_path : String = ""

static var _keep_displaying : bool = false

var _fade_tween : Tween

const _SETTINGS_WINDOW_SCENE : PackedScene = preload("res://windows/settingsWindow/SettingsWindow.tscn")
@onready var _settings_window : SettingsWindow = _SETTINGS_WINDOW_SCENE.instantiate()

var _current_open_file_path : String = ""

signal will_open_diferent_file

func _ready() -> void:
	_file_menu_button.get_popup().id_pressed.connect(_file_menu_button_id_pressed)
	
	_input_dialog.title = tr("Name of the folder")
	_input_dialog.define_text(tr("Type the name of the folder") + ":")
	_input_dialog.text_confirmed.connect(_input_dialog_text_confirmed)
	
	_player.play.connect(_is_playing)
	
	Global.changed_theme.connect(_changed_theme)
	
	add_child(_settings_window)
	
	Settings.changed_language.connect(_set_text_by_language)
	_set_text_by_language(Settings.get_language())
	
	_keep_displaying_button.button_pressed = _keep_displaying
	
	get_window().close_requested.connect(_on_close_requested)

func _set_text_by_language(_language : Settings.Languages) -> void:
	_file_menu_button.text = tr("File")
	_settings_button.text = tr("Settings")
	_keep_displaying_button.text = tr("Keep Displaying HUD")
	
	_file_menu_button.get_popup().set_item_text(0, tr("Open"))
	_file_menu_button.get_popup().set_item_text(1, tr("Import"))
	_file_menu_button.get_popup().set_item_text(2, tr("Open file location"))

func _changed_theme(_theme : Global.Themes) -> void:
	var current_theme : Theme
	
	match _theme:
		Global.Themes.DARK:
			current_theme = _DARK_THEME
		Global.Themes.WHITE:
			current_theme = _WHITE_THEME
	
	theme = current_theme

func _file_menu_button_id_pressed(id : int) -> void:
	match id:
		File.OPEN:
			_open()
		File.IMPORT:
			_import()
		File.OPEN_DIRECTORY:
			Files.open_extracted_texts_folder()

func _open() -> void:
	_open_file_dialog_to_open()

func _import() -> void:
	_open_file_dialog_to_import()

func _reset() -> void:
	_full_text.set_full_text("")

func _open_file_dialog_to_open() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_USERDATA
	_file_dialog.root_subfolder = "texts"
	_file_dialog.ok_button_text = tr("Open")
	_last_file_dialog_request = File.OPEN
	_file_dialog.popup_centered()

func _open_file_dialog_to_import() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.ok_button_text = tr("Open")
	_last_file_dialog_request = File.IMPORT
	_file_dialog.popup_centered()

func _on_file_dialog_file_selected(path: String) -> void:
	match _last_file_dialog_request:
		File.OPEN:
			_open_imported_file(path)
		File.IMPORT:
			if not path.get_extension() in Files.VALID_EXTENSION_IN_EXTRACTION:
				_accept_dialog.title = tr("Importation") + " - " + tr("Warning") + "!"
				_accept_dialog.dialog_text = tr("Error") + ": " + tr("Invalid file type") + "!\n" + tr("The accepted formats are") + ": " + str(Files.VALID_EXTENSION_IN_EXTRACTION)
				_accept_dialog.popup_centered()
				return
			_input_dialog.popup_centered()
			_last_import_path = path

func _input_dialog_text_confirmed(text : String) -> void:
	_accept_dialog.get_ok_button().disabled = true
	_accept_dialog.title = tr("Importation")
	_accept_dialog.dialog_text = tr("Importing file")
	_accept_dialog.popup_centered()
	await get_tree().create_timer(0.1).timeout
	var path : String = Files.EXTRACTED_TEXTS_PATH + "/" + text + ".txt"
	var status := await Files.import(_last_import_path, path)
	_accept_dialog.get_ok_button().disabled = false
	_open_accept_dialog_on_import(status)
	if status == OK:
		_open_imported_file(path)

func _open_accept_dialog_on_import(status : Error) -> void:
	_accept_dialog.title = tr("Importation") + " - " + tr("Warning") + "!"
	match status:
		ERR_FILE_NOT_FOUND:
			_accept_dialog.dialog_text = tr("Error") + ": " + tr("File not found") + "!"
		ERR_INVALID_DATA:
			_accept_dialog.dialog_text = tr("Error") + ": " + tr("Invalid file type") + "!\n" + tr("The accepted formats are") + ": " + str(Files.VALID_EXTENSION_IN_EXTRACTION)
		ERR_ALREADY_EXISTS:
			_accept_dialog.dialog_text = tr("Error") + ": " + tr("This name of file already exists") + "!"
		FAILED:
			_accept_dialog.dialog_text = tr("Error") + ": " + tr("Unknown") + "!"
		OK:
			_accept_dialog.dialog_text = tr("Success") + ": " + tr("The file was imported") + "!"
	_accept_dialog.popup_centered()

func _open_imported_file(file_path : String) -> void:
	if not _current_open_file_path.is_empty():
		Settings.save_data(ReaderThread.get_file_sha256_stream(_current_open_file_path), _full_text.get_page_n_word_idx())
	
	_accept_dialog.title = tr("Open") + " - " + tr("Warning") + "!"
	var status := Files.can_get_imported_file(file_path)
	if status != OK:
		if status == ERR_INVALID_DATA:
			_accept_dialog.dialog_text = tr("Error") + ": " + tr("It is only possible to open files in the following format") + ": \".txt\"\n" + tr("If you want to open a different file, try \"importing\" it first.") + "."
		elif status == ERR_FILE_NOT_FOUND:
			_accept_dialog.dialog_text = tr("Error") + ": " + tr("File not found") + "!"
		_accept_dialog.popup_centered()
	else:
		if _current_open_file_path != file_path:
			will_open_diferent_file.emit()
		Files.get_text_from_imported_file(file_path)
		_current_open_file_path = file_path
		
		var word_byte_pos = Settings.get_word_byte_pos(ReaderThread.get_file_sha256_stream(_current_open_file_path))
		if word_byte_pos >= 0:
			_full_text.set_last_word_byte_pos_in_focus(word_byte_pos)

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
	return not _current_open_file_path.is_empty()

func reopen_file() -> void:
	if _current_open_file_path.is_empty():
		return
	_open_imported_file(_current_open_file_path)

func _on_close_requested() -> void:
	if not _current_open_file_path.is_empty():
		Settings.save_data(ReaderThread.get_file_sha256_stream(_current_open_file_path), _full_text.get_page_n_word_idx())
