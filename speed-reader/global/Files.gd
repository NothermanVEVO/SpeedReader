extends Node

const EXTRACTED_TEXTS_PATH : String = "user://books"

const TOOLS_PATH : String = "user://tools"
const EXTRACT_FILE_PATH : String = TOOLS_PATH + "/extract_text_n_image.exe"

const TAGS_PATH : String = "user://tags.tres"

const LISTS_PATH : String = "user://lists"
const PREPARED_LISTS_PATH : String = LISTS_PATH + "/prepared_lists.tres"
const CUSTOM_LISTS_PATH : String = LISTS_PATH + "/custom_lists.tres"

enum ReadingTypes {NONE, READING, PLAN_TO_READ, COMPLETED, OH_HOLD, RE_READING, DROPPED}

const PREPARED_LIST_READING : String = "Reading"
const PREPARED_LIST_PLAN_TO_READ : String = "Plan to Read"
const PREPARED_LIST_COMPLETED : String = "Completed"
const PREPARED_LIST_ON_HOLD : String = "On Hold"
const PREPARED_LIST_RE_READING : String = "Re-reading"
const PREPARED_LIST_DROPPED : String = "Dropped"

const VALID_EXTENSION_IN_EXTRACTION : Array[String] = ["txt", "pdf", "doc", "docx", "epub"]
const VALID_IMAGE_EXTENSION : Array[String] = ["jpg", "jpeg", "png", "svg", "webp", "tga", "bmp", "dds", "ktx", "exr", "hdr"]

const _ERASE_CONFIRMATION_DIALOG_SCENE : PackedScene = preload("res://dialog/EraseConfirmationDialog.tscn")
@onready var _erase_confirmation_dialog : ConfirmationDialog = _ERASE_CONFIRMATION_DIALOG_SCENE.instantiate()

enum EraseType {NONE, BOOK, CUSTOM_LIST}

var _last_requested_erase_type : EraseType = EraseType.NONE

var _last_requested_book_to_erase : BookResource
var _last_requested_custom_list_to_erase : ListResource

var _books : Array[BookResource] = []

var _tags : TagsResource

var _all_list : ListResource = ListResource.new(PackedStringArray(), "Todos", Color(0.5, 0.5, 0.5, 1.0))
var _prepared_lists : ListsResource
var _custom_lists : ListsResource

enum SortType {LATEST = 0, OLDEST = 1, ALPHABETICAL_ASCEDING = 2, ALPHABETICAL_DESCEDING = 3}

var _current_book_sort_type : SortType = SortType.LATEST
var _current_custom_list_sort_type : SortType = SortType.LATEST

signal sorted_books(sort_type : SortType)
signal sorted_custom_lists(sort_type : SortType)

signal added_book(book : BookResource)

signal saved_book(book : BookResource, changed_cover : bool)

signal added_tag(tag : TagResource)
signal removed_tag(tag : TagResource)

signal erase_book(book : BookResource)
signal erase_custom_list(list : ListResource)

signal added_custom_list(list : ListResource)

signal saved_prepared_list(list : ListResource)
signal saved_custom_list(list : ListResource)

func _ready() -> void:
	add_child(_erase_confirmation_dialog)
	_erase_confirmation_dialog.confirmed.connect(_confirmed_to_erase_book)
	
	if not DirAccess.dir_exists_absolute(EXTRACTED_TEXTS_PATH):
		DirAccess.make_dir_absolute(EXTRACTED_TEXTS_PATH)

	if not DirAccess.dir_exists_absolute(TOOLS_PATH):
		DirAccess.make_dir_absolute(TOOLS_PATH)

	if not FileAccess.file_exists(TAGS_PATH):
		_tags = TagsResource.new()
		ResourceSaver.save(_tags, TAGS_PATH)
	else:
		_tags = ResourceLoader.load(TAGS_PATH)

	if not DirAccess.dir_exists_absolute(LISTS_PATH):
		DirAccess.make_dir_absolute(LISTS_PATH)

	if not FileAccess.file_exists(PREPARED_LISTS_PATH):
		_create_prepared_lists()
	else:
		_prepared_lists = ResourceLoader.load(PREPARED_LISTS_PATH)

	if not FileAccess.file_exists(CUSTOM_LISTS_PATH):
		_create_custom_lists()
	else:
		_custom_lists = ResourceLoader.load(CUSTOM_LISTS_PATH)

	if not FileAccess.file_exists(EXTRACT_FILE_PATH):
		var data := FileAccess.get_file_as_bytes("res://extern/extract_text/extract_text_n_image.exe")
		var f := FileAccess.open(EXTRACT_FILE_PATH, FileAccess.WRITE)
		f.store_buffer(data)
		f.close()
	
	_books = load_all_books_resources()
	set_book_sort_type(_current_book_sort_type)
	for book in _books:
		load_cover_image_from_book(book)
	
	set_custom_list_sort_type(_current_custom_list_sort_type)

func load_all_books_resources() -> Array[BookResource]:
	var result : Array[BookResource] = []

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

		var folder_path := EXTRACTED_TEXTS_PATH + "/" + folder_name

		if not dir.current_is_dir():
			continue

		var tres_path := folder_path + "/" + folder_name + ".tres"

		if not FileAccess.file_exists(tres_path):
			continue

		var res : BookResource = ResourceLoader.load(tres_path)

		if res == null:
			continue

		res.current_dir_path = folder_path

		result.append(res)

	dir.list_dir_end()

	return result

func unload_books() -> void:
	_books.clear()

func _create_prepared_lists() -> void:
	_prepared_lists = ListsResource.new()
	
	_prepared_lists.lists.append(ListResource.new(PackedStringArray(), PREPARED_LIST_READING, Color(0.5, 0.5, 0.5, 1.0)))
	_prepared_lists.lists.append(ListResource.new(PackedStringArray(), PREPARED_LIST_PLAN_TO_READ, Color(0.5, 0.5, 0.5, 1.0)))
	_prepared_lists.lists.append(ListResource.new(PackedStringArray(), PREPARED_LIST_COMPLETED, Color(0.5, 0.5, 0.5, 1.0)))
	_prepared_lists.lists.append(ListResource.new(PackedStringArray(), PREPARED_LIST_ON_HOLD, Color(0.5, 0.5, 0.5, 1.0)))
	_prepared_lists.lists.append(ListResource.new(PackedStringArray(), PREPARED_LIST_RE_READING, Color(0.5, 0.5, 0.5, 1.0)))
	_prepared_lists.lists.append(ListResource.new(PackedStringArray(), PREPARED_LIST_DROPPED, Color(0.5, 0.5, 0.5, 1.0)))
	
	ResourceSaver.save(_prepared_lists, PREPARED_LISTS_PATH)

func _create_custom_lists() -> void:
	_custom_lists = ListsResource.new()
	ResourceSaver.save(_custom_lists, CUSTOM_LISTS_PATH)

func import(from_path : String, to_path : String) -> Error:
	var dir_path : String = to_path.get_base_dir()
	
	if not FileAccess.file_exists(from_path):
		return ERR_FILE_NOT_FOUND
	
	if not from_path.get_extension() in VALID_EXTENSION_IN_EXTRACTION:
		return ERR_INVALID_DATA
	
	if DirAccess.dir_exists_absolute(dir_path):
		return ERR_ALREADY_EXISTS
	
	if FileAccess.file_exists(to_path):
		return ERR_ALREADY_EXISTS
	
	var dir_status : Error = DirAccess.make_dir_absolute(dir_path)
	if dir_status != OK:
		return dir_status
	
	if from_path.get_extension() == "txt":
		var data := FileAccess.get_file_as_bytes(from_path)
		var f := FileAccess.open(to_path, FileAccess.WRITE)
		var is_ok : bool = f.store_buffer(data)
		f.close()
		if is_ok:
			return OK
		else:
			return FAILED
	
	if ReaderThread.is_calculating_pages():
		ReaderThread.force_to_end()
		await ReaderThread.ended_by_force
	
	var exe_path := ProjectSettings.globalize_path(EXTRACT_FILE_PATH)
	var input := ProjectSettings.globalize_path(from_path)
	var output := ProjectSettings.globalize_path(to_path)
	var status = OS.execute(exe_path, [input, output])
	if status == 0:
		return OK
	else:
		return FAILED

func can_get_imported_file(file_path : String) -> Error:
	if file_path.get_extension() != "txt":
		return ERR_INVALID_DATA
	
	if not FileAccess.file_exists(file_path):
		return ERR_FILE_NOT_FOUND
	
	return OK

func get_text_from_imported_file(file_path : String) -> void:
	if ReaderThread.is_calculating_pages():
		ReaderThread.force_to_end()
		await ReaderThread.ended_by_force
	ReaderThread.calculate_pages(file_path, FullText.get_font(), FullText.get_font_size(), FullText.get_paragraph_width(), FullText.get_max_lines(), FullText.get_max_words())

func save_file(file_path : String, data : String, overrides : bool = false) -> Error:
	if not overrides and FileAccess.file_exists(file_path):
		return ERR_ALREADY_EXISTS
	var f := FileAccess.open(file_path, FileAccess.WRITE)
	var is_ok : bool = f.store_string(data)
	f.close()
	if is_ok:
		return OK
	else:
		return FAILED

func get_book_sort_type() -> SortType:
	return _current_book_sort_type

func set_book_sort_type(sort_type : SortType) -> void:
	_current_book_sort_type = sort_type
	
	match _current_book_sort_type:
		SortType.LATEST:
			_sort_books_by_latest()
		SortType.OLDEST:
			_sort_books_by_oldest()
		SortType.ALPHABETICAL_ASCEDING:
			_sort_books_by_name_ascending()
		SortType.ALPHABETICAL_DESCEDING:
			_sort_books_by_name_descending()
	
	sorted_books.emit(_current_book_sort_type)

func set_custom_list_sort_type(sort_type : SortType) -> void:
	_current_custom_list_sort_type = sort_type
	
	match _current_custom_list_sort_type:
		SortType.LATEST:
			_sort_custom_lists_by_latest()
		SortType.OLDEST:
			_sort_custom_lists_by_oldest()
		SortType.ALPHABETICAL_ASCEDING:
			_sort_custom_lists_by_name_ascending()
		SortType.ALPHABETICAL_DESCEDING:
			_sort_custom_lists_by_name_descending()
	
	sorted_custom_lists.emit(_current_custom_list_sort_type)

func _sort_books_by_latest() -> void:
	_books.sort_custom(func(a: BookResource, b: BookResource) -> bool:
		return a.creation_time > b.creation_time
	)

func _sort_books_by_oldest() -> void:
	_books.sort_custom(func(a: BookResource, b: BookResource) -> bool:
		return a.creation_time < b.creation_time
	)

func _sort_books_by_name_ascending() -> void:
	_books.sort_custom(func(a: BookResource, b: BookResource) -> bool:
		return (a.name.strip_edges().to_lower()
			< b.name.strip_edges().to_lower())
	)

func _sort_books_by_name_descending() -> void:
	_books.sort_custom(func(a: BookResource, b: BookResource) -> bool:
		return (a.name.strip_edges().to_lower()
			> b.name.strip_edges().to_lower())
	)

func _sort_custom_lists_by_latest() -> void:
	_custom_lists.lists.sort_custom(func(a: ListResource, b: ListResource) -> bool:
		return a.creation_time > b.creation_time
	)

func _sort_custom_lists_by_oldest() -> void:
	_custom_lists.lists.sort_custom(func(a: ListResource, b: ListResource) -> bool:
		return a.creation_time < b.creation_time
	)

func _sort_custom_lists_by_name_ascending() -> void:
	_custom_lists.lists.sort_custom(func(a: ListResource, b: ListResource) -> bool:
		return (a.name.strip_edges().to_lower()
			< b.name.strip_edges().to_lower())
	)

func _sort_custom_lists_by_name_descending() -> void:
	_custom_lists.lists.sort_custom(func(a: ListResource, b: ListResource) -> bool:
		return (a.name.strip_edges().to_lower()
			> b.name.strip_edges().to_lower())
	)

func save_book(book : BookResource) -> Error:
	var old_name : String = book.current_dir_path.get_file()
	if old_name != book.name:
		DirAccess.rename_absolute(book.current_dir_path, EXTRACTED_TEXTS_PATH + "/" + book.name)
		book.current_dir_path = EXTRACTED_TEXTS_PATH + "/" + book.name
		DirAccess.rename_absolute(book.current_dir_path + "/" + old_name + ".tres", book.current_dir_path + "/" + book.name + ".tres")
		DirAccess.rename_absolute(book.current_dir_path + "/" + old_name + ".txt", book.current_dir_path + "/" + book.name + ".txt")
	
	var status := ResourceSaver.save(book, book.current_dir_path + "/" + book.name + ".tres")
	if status == OK:
		saved_book.emit(book, false)
	return status

func load_cover_image_from_book(book : BookResource) -> void:
	var image_path = get_image_path_from_book(book)
	if FileAccess.file_exists(image_path):
		var image := Image.load_from_file(image_path)
		if image:
			book.cover_texture = ImageTexture.create_from_image(image)
	
	if not book.cover_texture:
		book.cover_texture = Books.FILE_ICON

func get_image_path_from_book(book : BookResource) -> String:
	var dir := DirAccess.open(book.current_dir_path)
	for file in dir.get_files():
		if file.begins_with("cover"):
			return book.current_dir_path + "/" + file
	return ""

func get_tags() -> TagsResource:
	return _tags

func can_add_tag(new_tag : TagResource) -> bool:
	for tag in _tags.tags:
		if tag.name == new_tag.name:
			return false
	return true

func add_tag(tag : TagResource) -> Error:
	_tags.tags.append(tag)
	var status := ResourceSaver.save(_tags, TAGS_PATH)
	if status != OK:
		_tags.tags.erase(tag)
	else:
		added_tag.emit(tag)
	return status

func remove_tag(tag : TagResource) -> Error:
	_tags.tags.erase(tag)
	var status := ResourceSaver.save(_tags, TAGS_PATH)
	if status != OK:
		_tags.tags.append(tag)
	else:
		for book in _books:
			for book_tag in book.tags.tags:
				if book_tag.name == tag.name:
					book.tags.tags.erase(book_tag)
					save_book(book)
					break
		for list in _custom_lists.lists:
			for list_tag in list.tags.tags:
				if list_tag.name == tag.name:
					list.tags.tags.erase(list_tag)
					save_custom_list(list)
					break
		removed_tag.emit(tag)
	return status

func get_book_tags_uids(book : BookResource) -> Array[String]:
	var uids : Array[String] = []
	for tag in book.tags.tags:
		uids.append(tag.name)
	return uids

func get_list_tags_uids(list : ListResource) -> Array[String]:
	var uids : Array[String] = []
	for tag in list.tags.tags:
		uids.append(tag.name)
	return uids

func open_extracted_texts_folder() -> void:
	var abs_path := ProjectSettings.globalize_path(Files.EXTRACTED_TEXTS_PATH)
	OS.shell_open(abs_path)

func can_load_image(path : String) -> bool:
	return path.get_extension() in VALID_IMAGE_EXTENSION

func load_image(path : String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	
	return ImageTexture.create_from_image(image)

func get_books() -> Array[BookResource]:
	return _books

func save_book_cover(book : BookResource, image_texture : Texture2D) -> Error:
	var status := image_texture.get_image().save_png(book.current_dir_path + "/cover.png")
	book.cover_texture = image_texture
	if status == OK:
		saved_book.emit(book, true)
	return status

func add_book(book : BookResource) -> Error:
	if _books.has(book):
		return FAILED
	_books.append(book)
	added_book.emit(book)
	return OK

func request_to_erase_book(book : BookResource) -> void:
	if not book:
		return
	_last_requested_erase_type = EraseType.BOOK
	_last_requested_book_to_erase = book
	_erase_confirmation_dialog.dialog_text = "Você tem certeza que deseja apagar o livro:\n\"" + book.name + "\""
	_erase_confirmation_dialog.popup_centered()

func request_to_erase_custom_list(list : ListResource) -> void:
	if not list:
		return
	_last_requested_erase_type = EraseType.CUSTOM_LIST
	_last_requested_custom_list_to_erase = list
	_erase_confirmation_dialog.dialog_text = "Você tem certeza que deseja apagar a lista:\n\"" + list.name + "\""
	_erase_confirmation_dialog.popup_centered()

func _confirmed_to_erase_book() -> void:
	match _last_requested_erase_type:
		EraseType.BOOK:
			if _last_requested_book_to_erase:
				erase_book.emit(_last_requested_book_to_erase)
				remove_dir_recursive(_last_requested_book_to_erase.current_dir_path)
				_books.erase(_last_requested_book_to_erase)
				
				for list in _custom_lists.lists:
					if _last_requested_book_to_erase.get_ID() in list.books_ids:
						list.books_ids.erase(_last_requested_book_to_erase.get_ID())
						save_custom_list(list)
				
				for list in _prepared_lists.lists:
					if _last_requested_book_to_erase.get_ID() in list.books_ids:
						list.books_ids.erase(_last_requested_book_to_erase.get_ID())
						save_prepared_lists(list)
				
				_last_requested_book_to_erase = null
		EraseType.CUSTOM_LIST:
			if _last_requested_custom_list_to_erase:
				_erase_custom_list(_last_requested_custom_list_to_erase)
				_last_requested_custom_list_to_erase = null

func remove_dir_recursive(path: String) -> Error:
	if not DirAccess.dir_exists_absolute(path):
		return ERR_DOES_NOT_EXIST

	var dir := DirAccess.open(path)
	if dir == null:
		return ERR_CANT_OPEN

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue

		var full_path := path + "/" + file_name

		if dir.current_is_dir():
			var err := remove_dir_recursive(full_path)
			if err != OK:
				dir.list_dir_end()
				return err
		else:
			var err := DirAccess.remove_absolute(full_path)
			if err != OK:
				dir.list_dir_end()
				return err

		file_name = dir.get_next()

	dir.list_dir_end()

	return DirAccess.remove_absolute(path)

func get_all_list() -> ListResource:
	return _all_list

func get_custom_lists() -> ListsResource:
	return _custom_lists

func get_prepared_lists() -> ListsResource:
	return _prepared_lists

func save_prepared_lists(list : ListResource) -> Error:
	var status := ResourceSaver.save(_prepared_lists, PREPARED_LISTS_PATH)
	if status == OK:
		saved_prepared_list.emit(list)
	return status

func get_prepared_list(reading_type : ReadingTypes) -> ListResource:
	match reading_type:
		ReadingTypes.READING:
			for list in _prepared_lists.lists:
				if list.name == PREPARED_LIST_READING:
					return list
		ReadingTypes.PLAN_TO_READ:
			for list in _prepared_lists.lists:
				if list.name == PREPARED_LIST_PLAN_TO_READ:
					return list
		ReadingTypes.COMPLETED:
			for list in _prepared_lists.lists:
				if list.name == PREPARED_LIST_COMPLETED:
					return list
		ReadingTypes.OH_HOLD:
			for list in _prepared_lists.lists:
				if list.name == PREPARED_LIST_ON_HOLD:
					return list
		ReadingTypes.RE_READING:
			for list in _prepared_lists.lists:
				if list.name == PREPARED_LIST_RE_READING:
					return list
		ReadingTypes.DROPPED:
			for list in _prepared_lists.lists:
				if list.name == PREPARED_LIST_DROPPED:
					return list
	return null

func remove_book_from_prepared_list(book : BookResource, reading_type : ReadingTypes) -> Error:
	var list := get_prepared_list(reading_type)
	if list:
		if book.get_ID() in list.books_ids:
			list.books_ids.erase(book.get_ID())
			return save_prepared_lists(list)
		else:
			return FAILED
	else:
		return FAILED

func add_book_to_prepared_list(book : BookResource, reading_type : ReadingTypes) -> Error:
	var list := get_prepared_list(reading_type)
	if list:
		if not book.get_ID() in list.books_ids:
			list.books_ids.append(book.get_ID())
			return save_prepared_lists(list)
		else:
			return FAILED
	else:
		return FAILED

func custom_lists_has_list(list : ListResource) -> bool:
	for custom_list in _custom_lists.lists:
		if custom_list.name == list.name:
			return true
	return false

func prepared_lists_has_list(list : ListResource) -> bool:
	for prepared_list in _prepared_lists.lists:
		if prepared_list.name == list.name:
			return true
	return false

func save_custom_list(list : ListResource) -> Error:
	var status := ResourceSaver.save(_custom_lists, CUSTOM_LISTS_PATH)
	if status == OK:
		saved_custom_list.emit(list)
	return status

func _erase_custom_list(list : ListResource) -> Error:
	erase_custom_list.emit(list)
	_custom_lists.lists.erase(list)
	var status := ResourceSaver.save(_custom_lists, CUSTOM_LISTS_PATH)
	return status

func add_custom_list(list : ListResource) -> Error:
	_custom_lists.lists.append(list)
	list.creation_time = Time.get_unix_time_from_system()
	var status := ResourceSaver.save(_custom_lists, CUSTOM_LISTS_PATH)
	if status == OK:
		added_custom_list.emit(list)
		set_custom_list_sort_type(_current_custom_list_sort_type)
	return status

func can_save_list(list_to_save : ListResource) -> bool:
	for list in _custom_lists.lists:
		if list.name == list_to_save.name and list != list_to_save:
			return false
	return true

func get_book(book_uid : String) -> BookResource:
	for book in _books:
		if book.get_ID() == book_uid:
			return book
	return null

func get_custom_lists_from_book(book : BookResource) -> Array[ListResource]:
	var lists : Array[ListResource] = []
	
	for list in _custom_lists.lists:
		if book.get_ID() in list.books_ids:
			lists.append(list)
	
	return lists
