extends Node

const EXTRACTED_TEXTS_PATH : String = "user://books"
const TOOLS_PATH : String = "user://tools"
const EXTRACT_FILE_PATH : String = TOOLS_PATH + "/extract_text.exe"
const TAGS_PATH : String = "user://tags.tres"

const VALID_EXTENSION_IN_EXTRACTION : Array[String] = ["txt", "pdf", "doc", "docx", "epub"]
const VALID_IMAGE_EXTENSION : Array[String] = ["jpg", "jpeg", "png", "svg", "webp", "tga", "bmp", "dds", "ktx", "exr", "hdr"]

const _ERASE_CONFIRMATION_DIALOG_SCENE : PackedScene = preload("res://dialog/EraseConfirmationDialog.tscn")
@onready var _erase_confirmation_dialog : ConfirmationDialog = _ERASE_CONFIRMATION_DIALOG_SCENE.instantiate()

var _last_requested_book_to_erase : BookResource

var _tags : TagsResource

signal saved_book(book : BookResource, changed_cover : bool)

signal added_tag(tag : TagResource)
signal removed_tag(tag : TagResource)

signal erase_book(book : BookResource)

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
	
	#for tag in _tags.tags:
		#print(tag.name)
		#print(tag.background_color)

	if not FileAccess.file_exists(EXTRACT_FILE_PATH):
		var data := FileAccess.get_file_as_bytes("res://extern/extract_text/extract_text.exe")
		var f := FileAccess.open(EXTRACT_FILE_PATH, FileAccess.WRITE)
		f.store_buffer(data)
		f.close()

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

func load_cover_image_from_book(book : BookResource) -> Texture2D:
	var _cover_image_texture : Texture2D
	
	if FileAccess.file_exists(book.current_dir_path + "/cover.png"):
		var image := Image.load_from_file(book.current_dir_path + "/cover.png")
		if image:
			_cover_image_texture = ImageTexture.create_from_image(image)
	
	if not _cover_image_texture:
		_cover_image_texture = Books.FILE_ICON
	
	return _cover_image_texture

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
		removed_tag.emit(tag)
	return status

func get_books_tags_uids(book : BookResource) -> Array[String]:
	var uids : Array[String] = []
	for tag in book.tags.tags:
		uids.append(tag.resource_scene_unique_id)
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

func save_book_cover(book : BookResource, image_texture : Texture2D) -> Error:
	var status := image_texture.get_image().save_png(book.current_dir_path + "/cover.png")
	if status == OK:
		saved_book.emit(book, true)
	return status

func request_to_erase_book(book : BookResource) -> void:
	if not book:
		return
	_last_requested_book_to_erase = book
	_erase_confirmation_dialog.dialog_text = "Você tem certeza que deseja apagar o livro:\n\"" + book.name + "\""
	_erase_confirmation_dialog.popup_centered()

func _confirmed_to_erase_book() -> void:
	if _last_requested_book_to_erase:
		erase_book.emit(_last_requested_book_to_erase)
		remove_dir_recursive(_last_requested_book_to_erase.current_dir_path)
		_last_requested_book_to_erase = null

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
