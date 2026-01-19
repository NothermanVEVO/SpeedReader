extends Node

const EXTRACTED_TEXTS_PATH : String = "user://texts"
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
	if not FileAccess.file_exists(from_path):
		return ERR_FILE_NOT_FOUND
	
	if not from_path.get_extension() in VALID_EXTENSION_IN_EXTRACTION:
		return ERR_INVALID_DATA
	
	if FileAccess.file_exists(to_path):
		return ERR_ALREADY_EXISTS
	
	if from_path.get_extension() == "txt":
		var data := FileAccess.get_file_as_bytes(from_path)
		var f := FileAccess.open(to_path, FileAccess.WRITE)
		var is_ok : bool = f.store_buffer(data)
		f.close()
		if is_ok:
			return OK
		else:
			return FAILED
	
	var exe_path := ProjectSettings.globalize_path(EXTRACT_FILE_PATH)
	var input := ProjectSettings.globalize_path(from_path)
	var output := ProjectSettings.globalize_path(to_path)
	var status = OS.execute(exe_path, [input, output])
	if status == 0:
		return OK
	else:
		return FAILED

func get_text_from(file_path : String) -> String:
	#var file_path : String = EXTRACTED_TEXTS_PATH + "/" + file_name + ".txt"
	if not FileAccess.file_exists(file_path):
		return ""
	var file := FileAccess.open(file_path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	return text

func save_file(file_path : String, data : String) -> Error:
	if FileAccess.file_exists(file_path):
		return ERR_ALREADY_EXISTS
	var f := FileAccess.open(file_path, FileAccess.WRITE)
	var is_ok : bool = f.store_string(data)
	f.close()
	if is_ok:
		return OK
	else:
		return FAILED
