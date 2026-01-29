extends MarginContainer

class_name Books

const FILE_ICON : CompressedTexture2D = preload("res://assets/icons/file.png")

@onready var _long_books : VBoxContainer = $HBoxContainer/MiddleBar/VBoxContainer/Books/LongBooks
@onready var _block_books : FlowContainer = $HBoxContainer/MiddleBar/VBoxContainer/Books/BlockBooks

const _LONG_BOOK_SCENE : PackedScene = preload("res://books/longBook/LongBook.tscn")
const _BLOCK_BOOK_SCENE : PackedScene = preload("res://books/blockBook/BlockBook.tscn")

enum ShowType {LONG = 0, BLOCK = 1}
var _current_show_type : ShowType

enum SortType {LATEST, OLDEST, ALPHABETICAL_ASCEDING, ALPHABETICAL_DESCEDING}
var _current_sort_type : SortType

var _books : Array[Book] = []

@onready var _file_dialog : FileDialog = $FileDialog
@onready var _accept_dialog : AcceptDialog = $AcceptDialog
@onready var _input_dialog : InputDialog = $InputDialog

var _last_file_path : String = ""

signal changed_books_order

func _ready() -> void:
	_input_dialog.title = tr("Name of the folder")
	_input_dialog.define_placeholder_text(tr("Type the name of the folder") + ":")
	_input_dialog.text_confirmed.connect(_input_dialog_text_confirmed)
	
	var books := load_all_extracted_resources()
	for book in books:
		add_book(book)

func _set_current_show_type(show_type : ShowType) -> void:
	_clear_books_nodes() ## CLEARS FIRST
	
	_current_show_type = show_type
	
	match _current_show_type:
		ShowType.LONG:
			_long_books.visible = true
			_block_books.visible = false
		ShowType.BLOCK:
			_long_books.visible = false
			_block_books.visible = true
	
	for book in _books:
		add_book(book, false)

func _clear_books_nodes() -> void:
	var books_size : int = _books.size()
	for i in books_size:
		remove_book(_books[i], false)

func _set_current_sort_type(sort_type : SortType) -> void:
	_current_sort_type = sort_type

func load_all_extracted_resources() -> Array[Book]:
	var result : Array[Book] = []

	var dir := DirAccess.open(Files.EXTRACTED_TEXTS_PATH)
	if dir == null:
		return result

	dir.list_dir_begin()

	while true:
		var folder_name := dir.get_next()
		if folder_name == "":
			break

		if folder_name.begins_with("."):
			continue

		var folder_path := Files.EXTRACTED_TEXTS_PATH + "/" + folder_name

		if not dir.current_is_dir():
			continue

		var tres_path := folder_path + "/" + folder_name + ".tres"

		if not FileAccess.file_exists(tres_path):
			continue

		var res : Book = ResourceLoader.load(tres_path)

		if res == null:
			continue

		res.current_dir_path = folder_path

		result.append(res)

	dir.list_dir_end()

	return result

func add_book(book : Book, append_resource_book : bool = true) -> void:
	if append_resource_book:
		_books.append(book)
	
	match _current_show_type:
		ShowType.LONG:
			var long_book : LongBook = _LONG_BOOK_SCENE.instantiate()
			_long_books.add_child(long_book)
			long_book.load_book(book) # NEED TO BE AFTER BECAUSE OF THE _READY
		ShowType.BLOCK:
			var block_book : BlockBook = _BLOCK_BOOK_SCENE.instantiate()
			_block_books.add_child(block_book)
			block_book.load_book(book) # NEED TO BE AFTER BECAUSE OF THE _READY
	
	if append_resource_book:
		changed_books_order.emit()

func remove_book(book : Book, erase_resource_book : bool = true) -> void:
	match _current_show_type:
		ShowType.LONG:
			for child in _long_books.get_children():
				if child is LongBook and child.get_book() == book:
					_long_books.remove_child(child)
					child.queue_free()
					break
		ShowType.BLOCK:
			for child in _block_books.get_children():
				if child is BlockBook and child.get_book() == book:
					_block_books.remove_child(child)
					child.queue_free()
					break
	
	if erase_resource_book:
		_books.erase(book)
		changed_books_order.emit()

func _on_new_file_pressed() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.ok_button_text = tr("Open")
	_file_dialog.popup_centered()

func _on_file_dialog_file_selected(path: String) -> void:
	if not path.get_extension() in Files.VALID_EXTENSION_IN_EXTRACTION: ## INVALID FILE TYPE ERROR
		_accept_dialog.title = tr("Importation") + " - " + tr("Warning") + "!"
		_accept_dialog.dialog_text = tr("Error") + ": " + tr("Invalid file type") + "!\n" + tr("The accepted formats are") + ": " + str(Files.VALID_EXTENSION_IN_EXTRACTION)
		_accept_dialog.popup_centered()
		return
	
	_last_file_path = path
	
	_input_dialog.define_text(path.get_basename().get_file())
	_input_dialog.popup_centered()

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

func _input_dialog_text_confirmed(text : String) -> void:
	if DirAccess.dir_exists_absolute(Files.EXTRACTED_TEXTS_PATH + "/" + text):
		_input_dialog.define_text.call_deferred(text)
		_input_dialog.popup_centered.call_deferred()
		_open_accept_dialog_on_import.call_deferred(ERR_ALREADY_EXISTS)
		return
	
	_accept_dialog.get_ok_button().disabled = true
	_accept_dialog.title = tr("Importation")
	_accept_dialog.dialog_text = tr("Importing file")
	_accept_dialog.popup_centered()
	await get_tree().create_timer(0.1).timeout
	var import_file_path : String = Files.EXTRACTED_TEXTS_PATH + "/" + text + "/" + text + ".txt"
	var status := await Files.import(_last_file_path, import_file_path)
	_accept_dialog.get_ok_button().disabled = false
	
	if status == OK:
		var book := Book.new(text, 0, 0, "", [])
		book.current_dir_path = import_file_path.get_base_dir()
		var book_status := ResourceSaver.save(book, import_file_path.get_basename() + ".tres")
		_open_accept_dialog_on_import(book_status)
		if book_status == OK:
			add_book(book)
	else:
		_open_accept_dialog_on_import(status)

func _on_show_type_option_item_selected(index: int) -> void:
	_set_current_show_type(index as ShowType)

func _on_sort_option_item_selected(index: int) -> void:
	_set_current_sort_type(index as SortType)
