extends Node

const EXTRACTED_TEXTS_PATH : String = "user://books"
const TOOLS_PATH : String = "user://tools"
const EXTRACT_FILE_PATH : String = TOOLS_PATH + "/extract_text.exe"

const VALID_EXTENSION_IN_EXTRACTION : Array[String] = ["txt", "pdf", "doc", "docx", "epub"]

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(EXTRACTED_TEXTS_PATH):
		DirAccess.make_dir_absolute(EXTRACTED_TEXTS_PATH)

	if not DirAccess.dir_exists_absolute(TOOLS_PATH):
		DirAccess.make_dir_absolute(TOOLS_PATH)

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

func open_extracted_texts_folder() -> void:
	var abs_path := ProjectSettings.globalize_path(Files.EXTRACTED_TEXTS_PATH)
	OS.shell_open(abs_path)
