extends MarginContainer

class_name Books

const FILE_ICON : CompressedTexture2D = preload("res://assets/icons/file.png")

@onready var _long_books : VBoxContainer = $HBoxContainer/MiddleBar/VBoxContainer/Books/LongBooks
@onready var _block_books : FlowContainer = $HBoxContainer/MiddleBar/VBoxContainer/Books/BlockBooks
@onready var _book_info : BookInfo = $HBoxContainer/RightBar

const _LONG_BOOK_SCENE : PackedScene = preload("res://books/longBook/LongBook.tscn")
const _BLOCK_BOOK_SCENE : PackedScene = preload("res://books/blockBook/BlockBook.tscn")

var _manage_lists_container_scene : PackedScene = load("res://books/list/manageListsContainer/ManageListsContainer.tscn")

enum ShowType {LONG = 0, BLOCK = 1}
var _current_show_type : ShowType

var _books : Array[BookResource] = []

@onready var _search_line_edit : LineEdit = $HBoxContainer/MiddleBar/VBoxContainer/SearchBar/SearchLineEdit

@onready var _tags_window : TagsWindow = $TagsWindow
@onready var _file_dialog : FileDialog = $FileDialog
@onready var _accept_dialog : AcceptDialog = $AcceptDialog
@onready var _input_dialog : InputDialog = $InputDialog

var _current_sort_type : Files.SortType

var _last_file_path : String = ""

var _last_toggled_long_book : LongBook
var _last_toggled_block_book : BlockBook

var _filtered_books_visibility : Array[bool] = []

var _last_include_tags : Array[TagResource] = []
var _last_exclude_tags : Array[TagResource] = []
var _last_include_mode : TagsWindow.OptionMode
var _last_exclude_mode : TagsWindow.OptionMode

func _ready() -> void:
	_input_dialog.title = tr("Name of the folder")
	_input_dialog.define_placeholder_text(tr("Type the name of the folder") + ":")
	_input_dialog.text_confirmed.connect(_input_dialog_text_confirmed)
	
	_books = Files.get_books()
	
	for book in _books:
		_add_book(book)
	
	Files.erase_book.connect(_remove_book)
	Files.sorted_books.connect(_files_sorted_books)
	_tags_window.confirmation_pressed.connect(_tags_window_confirmation_pressed)

func _files_sorted_books(sort_type : Files.SortType) -> void:
	_current_sort_type = sort_type
	
	match _current_show_type:
		ShowType.LONG:
			for i in _books.size():
				for child in _long_books.get_children():
					if child is LongBook and child.get_book() == _books[i]:
						_long_books.move_child.call_deferred(child, i)
		ShowType.BLOCK:
			for i in _books.size():
				for child in _block_books.get_children():
					if child is BlockBook and child.get_book() == _books[i]:
						_block_books.move_child.call_deferred(child, i)

func _tags_window_confirmation_pressed(include_tags : Array[TagResource], exclude_tags : Array[TagResource], include_mode : TagsWindow.OptionMode, exclude_mode : TagsWindow.OptionMode) -> void:
	_last_include_tags = include_tags
	_last_exclude_tags = exclude_tags
	_last_include_mode = include_mode
	_last_exclude_mode = exclude_mode
	
	_filtered_books_visibility.clear()
	
	if _current_show_type == ShowType.LONG:
		for child in _long_books.get_children():
			child.visible = true
			_filtered_books_visibility.append(true)
	else:
		for child in _block_books.get_children():
			child.visible = true
			_filtered_books_visibility.append(true)
	
	set_invisible_books(include_tags, include_mode, true)
	set_invisible_books(exclude_tags, exclude_mode, false)
	
	_on_search_line_edit_text_changed(_search_line_edit.text)

func set_invisible_books(tags : Array[TagResource], option_mode : TagsWindow.OptionMode, is_include : bool) -> void:
	if tags.is_empty():
		return
	
	if option_mode == TagsWindow.OptionMode.AND:
		for i in _books.size():
			var tags_uids := _books[i].get_tags_uids()
			var has_tag := true
			for tag in tags:
				has_tag = tag.name in tags_uids
				if not has_tag:
					break
			if (is_include and not has_tag) or (not is_include and has_tag):
				if _current_show_type == ShowType.LONG:
					_long_books.get_child(i).visible = false
					_filtered_books_visibility[i] = false
				else:
					_block_books.get_child(i).visible = false
					_filtered_books_visibility[i] = false
	else: ## OR
		for i in _books.size():
			var tags_uids := _books[i].get_tags_uids()
			var has_tag := false
			for tag in tags:
				has_tag = tag.name in tags_uids
				if has_tag:
					break
			if (is_include and not has_tag) or (not is_include and has_tag):
				if _current_show_type == ShowType.LONG:
					_long_books.get_child(i).visible = false
					_filtered_books_visibility[i] = false
				else:
					_block_books.get_child(i).visible = false
					_filtered_books_visibility[i] = false

func _set_current_show_type(show_type : ShowType) -> void:
	var _last_pressed_book : BookResource
	
	if _last_toggled_block_book:
		_last_pressed_book = _last_toggled_block_book.get_book()
		_last_toggled_block_book = null
	if _last_toggled_long_book:
		_last_pressed_book = _last_toggled_long_book.get_book()
		_last_toggled_long_book = null
	
	_clear_books_nodes() ## NEEDS TO CLEAR BEFORE CHANGING TYPE
	
	_current_show_type = show_type
	
	for book in _books:
		_add_book(book)
	
	match _current_show_type:
		ShowType.LONG:
			if _last_pressed_book:
				for child in _long_books.get_children():
					if child is LongBook and child.get_book() == _last_pressed_book:
						child.button_pressed = true
			_long_books.visible = true
			_block_books.visible = false
		ShowType.BLOCK:
			if _last_pressed_book:
				for child in _block_books.get_children():
					if child is BlockBook and child.get_book() == _last_pressed_book:
						child.set_pressed()
			_long_books.visible = false
			_block_books.visible = true
	
	_tags_window_confirmation_pressed.call_deferred(_last_include_tags, _last_exclude_tags, _last_include_mode, _last_exclude_mode)

func _clear_books_nodes() -> void:
	var books_size : int = _books.size()
	for i in books_size:
		_remove_book(_books[i])

func _set_current_sort_type(sort_type : Files.SortType) -> void:
	_current_sort_type = sort_type
	
	Files.set_book_sort_type(_current_sort_type)

func _add_book(book : BookResource) -> void:
	_filtered_books_visibility.append(true)
	match _current_show_type:
		ShowType.LONG:
			var long_book : LongBook = _LONG_BOOK_SCENE.instantiate()
			_long_books.add_child(long_book)
			long_book.load_book(book) # NEED TO BE AFTER BECAUSE OF THE _READY
			long_book.has_toggled.connect(_has_toggled_long_book)
		ShowType.BLOCK:
			var block_book : BlockBook = _BLOCK_BOOK_SCENE.instantiate()
			_block_books.add_child(block_book)
			block_book.load_book(book) # NEED TO BE AFTER BECAUSE OF THE _READY
			block_book.has_toggled.connect(_has_toggled_block_book)

func _remove_book(book : BookResource) -> void:
	match _current_show_type:
		ShowType.LONG:
			for child in _long_books.get_children():
				if child is LongBook and child.get_book() == book:
					_filtered_books_visibility.remove_at(child.get_index())
					child.has_toggled.disconnect(_has_toggled_long_book)
					_long_books.remove_child(child)
					child.queue_free()
					break
		ShowType.BLOCK:
			for child in _block_books.get_children():
				if child is BlockBook and child.get_book() == book:
					_filtered_books_visibility.remove_at(child.get_index())
					child.has_toggled.disconnect(_has_toggled_block_book)
					_block_books.remove_child(child)
					child.queue_free()
					break

func _has_toggled_long_book(long_book : LongBook, toggled_on : bool) -> void:
	if _last_toggled_long_book and not toggled_on and _last_toggled_long_book == long_book:
		_book_info.visible = false
		_last_toggled_long_book = null
		return
	
	if _last_toggled_long_book and long_book != _last_toggled_long_book:
		if toggled_on:
			_last_toggled_long_book.button_pressed = false
			_last_toggled_long_book = null
	
	if toggled_on:
		_last_toggled_long_book = long_book
		if not _book_info.get_book() or (_book_info.get_book() and _book_info.get_book() != long_book.get_book()):
			_book_info.load_book(long_book.get_book())
		_book_info.visible = true

func _has_toggled_block_book(block_book : BlockBook, toggled_on : bool) -> void:
	if _last_toggled_block_book and not toggled_on and _last_toggled_block_book == block_book:
		_book_info.visible = false
		_last_toggled_block_book = null
		return
	
	if _last_toggled_block_book and block_book != _last_toggled_block_book:
		if toggled_on:
			_last_toggled_block_book.set_unpressed()
			_last_toggled_block_book = null
	
	if toggled_on:
		_last_toggled_block_book = block_book
		if not _book_info.get_book() or (_book_info.get_book() and _book_info.get_book() != block_book.get_book()):
			_book_info.load_book(block_book.get_book())
		_book_info.visible = true

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
		var book := BookResource.new(text, 0, 0, "", TagsResource.new())
		book.current_dir_path = import_file_path.get_base_dir()
		book.creation_time = Time.get_unix_time_from_system()
		var book_status := Files.save_book(book)
		_open_accept_dialog_on_import(book_status)
		if book_status == OK:
			Files.add_book(book)
			_set_current_sort_type(_current_sort_type)
	else:
		_open_accept_dialog_on_import(status)

func _on_show_type_option_item_selected(index: int) -> void:
	_set_current_show_type(index as ShowType)

func _on_sort_option_item_selected(index: int) -> void:
	_set_current_sort_type(index as Files.SortType)

func _on_filter_pressed() -> void:
	_tags_window.popup_centered()

func _on_search_line_edit_text_changed(new_text: String) -> void:
	new_text = new_text.to_lower()
	if _current_show_type == ShowType.LONG:
		var long_books : Array[Node] = _long_books.get_children()
		for i in long_books.size():
			if long_books[i] is LongBook:
				var search_visible : bool = true if new_text.is_empty() else new_text in long_books[i].get_book().name.to_lower()
				long_books[i].visible = search_visible and _filtered_books_visibility[i]
	else:
		var block_books : Array[Node] = _block_books.get_children()
		for i in block_books.size():
			if block_books[i] is BlockBook:
				var search_visible : bool = true if new_text.is_empty() else new_text in block_books[i].get_book().name.to_lower()
				block_books[i].visible = search_visible and _filtered_books_visibility[i]

func _on_manage_list_button_pressed() -> void:
	get_tree().change_scene_to_packed(_manage_lists_container_scene)
