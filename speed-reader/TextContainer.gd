extends MarginContainer

class_name TextContainer

enum File {NEW = 0, OPEN = 1, IMPORT = 2, SAVE = 3, SAVE_AS = 4}

@onready var _menu_button : MenuButton = $VBoxContainer/Top/HBoxContainer/File

@onready var _file_dialog : FileDialog = $FileDialog
@onready var _accept_dialog : AcceptDialog = $AcceptDialog
@onready var _input_dialog : InputDialog = $InputDialog
@onready var _confirmation_dialog : ConfirmationDialog = $ConfirmationDialog
var _custom_confirmation_dialog_button : Button

@onready var _full_text : FullText = $VBoxContainer/FullText
@onready var _text_edit : TextEdit = $VBoxContainer/TextEdit

@onready var _edit_button : Button = $VBoxContainer/Top/HBoxContainer/Edit

var _has_unsaved_changes : bool = false

var _is_editing : bool = false

signal editing_text(is_editing : bool)

var _last_file_dialog_request : File

var _last_import_path : String = ""

var _currently_file_save_path : String = ""

func _ready() -> void:
	_menu_button.get_popup().id_pressed.connect(_menu_button_id_pressed)
	
	_input_dialog.title = "Nome do arquivo"
	_input_dialog.define_text("Digite o nome do arquivo:")
	_input_dialog.text_confirmed.connect(_input_dialog_text_confirmed)
	
	_custom_confirmation_dialog_button = _confirmation_dialog.add_button("Não salvar", false, "Negar")

func is_editing() -> bool:
	return _is_editing

func get_text() -> String:
	return _text_edit.text

func _menu_button_id_pressed(id : int) -> void:
	match id:
		File.NEW:
			_new()
		File.OPEN:
			_open()
		File.IMPORT:
			_import()
		File.SAVE:
			_save()
		File.SAVE_AS:
			_save_as()

func _new() -> void:
	if _has_unsaved_changes:
		_confirmation_dialog.dialog_text = "O arquivo não está salvo."
		_custom_confirmation_dialog_button.text = "Não salvar"
		_confirmation_dialog.popup_centered()
		return
	_reset()

func _open() -> void:
	_open_file_dialog_to_open()

func _import() -> void:
	_open_file_dialog_to_import()

func _save() -> void:
	if _currently_file_save_path.is_empty():
		_save_as()
		return
	_last_file_dialog_request = File.SAVE
	_on_file_dialog_file_selected(_currently_file_save_path)

func _save_as() -> void:
	if _get_full_text().is_empty():
		return
	
	_open_file_dialog_to_save()

func _reset() -> void:
	_currently_file_save_path = ""
	_full_text.set_full_text("")
	_text_edit.text = ""

func _open_file_dialog_to_open() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_USERDATA
	_file_dialog.root_subfolder = "texts"
	_file_dialog.ok_button_text = "Abrir"
	_last_file_dialog_request = File.OPEN
	_file_dialog.popup_centered()

func _open_file_dialog_to_import() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.ok_button_text = "Abrir"
	_last_file_dialog_request = File.IMPORT
	_file_dialog.popup_centered()

func _open_file_dialog_to_save() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.access = FileDialog.ACCESS_USERDATA
	_file_dialog.root_subfolder = "texts"
	_file_dialog.ok_button_text = "Salvar"
	_last_file_dialog_request = File.SAVE
	_file_dialog.popup_centered()

func _get_full_text() -> String:
	if _is_editing:
		return _text_edit.text
	else:
		return _full_text.get_full_text()

func _on_edit_toggled(toggled_on: bool) -> void:
	_is_editing = toggled_on
	editing_text.emit(_is_editing)
	_edit_button.release_focus()
	if toggled_on:
		_edit_button.text = "Parar edição"
		_full_text.visible = false
		_text_edit.visible = true
		_text_edit.text = _full_text.get_full_text()
		_full_text.disable_pages()
	else:
		_edit_button.text = "Editar"
		_full_text.visible = true
		_text_edit.visible = false
		_full_text.set_full_text(_text_edit.text)

func _on_file_dialog_file_selected(path: String) -> void:
	match _last_file_dialog_request:
		File.OPEN:
			_open_imported_file(path)
		File.IMPORT:
			if not path.get_extension() in Files.VALID_EXTENSION_IN_EXTRACTION:
				_accept_dialog.title = "Importação - Aviso!"
				_accept_dialog.dialog_text = "Erro: Tipo de arquivo inválido!\nOs formatos aceitos são: " + str(Files.VALID_EXTENSION_IN_EXTRACTION)
				_accept_dialog.popup_centered()
				return
			_input_dialog.popup_centered()
			_last_import_path = path
		File.SAVE:
			var overrides : bool = not _currently_file_save_path.is_empty()
			var status := Files.save_file(path.get_basename() + ".txt", _get_full_text(), overrides)
			_open_accept_dialog_on_save(status)

func _input_dialog_text_confirmed(text : String) -> void:
	_accept_dialog.get_ok_button().disabled = true
	_accept_dialog.title = "Importação"
	_accept_dialog.dialog_text = "Importando arquivo..."
	_accept_dialog.popup_centered()
	await get_tree().create_timer(0.5).timeout
	var path : String = Files.EXTRACTED_TEXTS_PATH + "/" + text + ".txt"
	var status := Files.import(_last_import_path, path)
	_accept_dialog.get_ok_button().disabled = false
	_open_accept_dialog_on_import(status)
	if status == OK:
		_open_imported_file(path)

func _open_accept_dialog_on_import(status : Error) -> void:
	_accept_dialog.title = "Importação - Aviso!"
	match status:
		ERR_FILE_NOT_FOUND:
			_accept_dialog.dialog_text = "Erro: Arquivo não encontrado!"
		ERR_INVALID_DATA:
			_accept_dialog.dialog_text = "Erro: Tipo de arquivo inválido!\nOs formatos aceitos são: " + str(Files.VALID_EXTENSION_IN_EXTRACTION)
		ERR_ALREADY_EXISTS:
			_accept_dialog.dialog_text = "Erro: Esse nome de arquivo já existe!"
		FAILED:
			_accept_dialog.dialog_text = "Erro: Desconhecido!"
		OK:
			_accept_dialog.dialog_text = "Sucesso: O arquivo foi importado!"
	_accept_dialog.popup_centered()

func _open_accept_dialog_on_save(status : Error) -> void:
	_accept_dialog.title = "Salvamento - Aviso!"
	match status:
		ERR_ALREADY_EXISTS:
			_accept_dialog.dialog_text = "Erro: O arquivo já existe!"
		FAILED:
			_accept_dialog.dialog_text = "Erro: Desconhecido!"
		OK:
			_accept_dialog.dialog_text = "Sucesso: O arquivo foi salvo."
	_accept_dialog.popup_centered()

func _open_imported_file(file_path : String) -> void:
	_accept_dialog.title = "Abrir - Aviso!"
	var status := Files.can_get_imported_file(file_path)
	if status != OK:
		if status == ERR_INVALID_DATA:
			_accept_dialog.dialog_text = "Erro: Só é possivel abrir arquivos em formato \".txt\"\nSe quiser abrir algum arquivo diferente, tente \"importar\" primeiro."
		elif status == ERR_FILE_NOT_FOUND:
			_accept_dialog.dialog_text = "Erro: Arquivo não encontrado!"
		_accept_dialog.popup_centered()
	else:
		Files.get_text_from_imported_file(file_path)
		_currently_file_save_path = file_path
		#_full_text.set_full_text(text)
		#_text_edit.text = text

func _on_confirmation_dialog_confirmed() -> void:
	_save()

func _on_confirmation_dialog_custom_action(_action: StringName) -> void:
	if _custom_confirmation_dialog_button.text == "Não salvar":
		_reset()
	elif _custom_confirmation_dialog_button.text == "Sair":
		get_tree().quit()
