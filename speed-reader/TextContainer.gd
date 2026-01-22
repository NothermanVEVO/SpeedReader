extends MarginContainer

class_name TextContainer

enum File {OPEN = 0, IMPORT = 1}

@onready var _menu_button : MenuButton = $VBoxContainer/Top/HBoxContainer/File

@onready var _file_dialog : FileDialog = $FileDialog
@onready var _accept_dialog : AcceptDialog = $AcceptDialog
@onready var _input_dialog : InputDialog = $InputDialog

@onready var _full_text : FullText = $VBoxContainer/FullText

var _last_file_dialog_request : File

var _last_import_path : String = ""

func _ready() -> void:
	_menu_button.get_popup().id_pressed.connect(_menu_button_id_pressed)
	
	_input_dialog.title = "Nome do arquivo"
	_input_dialog.define_text("Digite o nome do arquivo:")
	_input_dialog.text_confirmed.connect(_input_dialog_text_confirmed)

func _menu_button_id_pressed(id : int) -> void:
	match id:
		File.OPEN:
			_open()
		File.IMPORT:
			_import()

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
	_file_dialog.ok_button_text = "Abrir"
	_last_file_dialog_request = File.OPEN
	_file_dialog.popup_centered()

func _open_file_dialog_to_import() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.ok_button_text = "Abrir"
	_last_file_dialog_request = File.IMPORT
	_file_dialog.popup_centered()

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

func _input_dialog_text_confirmed(text : String) -> void:
	_accept_dialog.get_ok_button().disabled = true
	_accept_dialog.title = "Importação"
	_accept_dialog.dialog_text = "Importando arquivo..."
	_accept_dialog.popup_centered()
	await get_tree().create_timer(0.1).timeout
	var path : String = Files.EXTRACTED_TEXTS_PATH + "/" + text + ".txt"
	var status := await Files.import(_last_import_path, path)
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
		#_full_text.set_full_text(text)
		#_text_edit.text = text
