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
	
	#print(export_text("C:\\Users\\Noth\\Downloads\\Cópia de Cópia de Detecção de formas geométricas para uma competição de drones usando YOLOv4 Tiny V2.docx"))

func export_text(file_path : String) -> Error:
	if not file_path.get_extension() in VALID_EXTENSION_IN_EXTRACTION:
		return Error.ERR_INVALID_DATA
	
	var exe_path := ProjectSettings.globalize_path(EXTRACT_FILE_PATH)
	var input := ProjectSettings.globalize_path(file_path)
	var output := ProjectSettings.globalize_path(EXTRACTED_TEXTS_PATH + "/" + file_path.get_file().get_basename() + ".txt")
	var status = OS.execute(exe_path, [input, output])
	if status == 0:
		return OK
	else:
		return Error.FAILED

func split_text_by_space(text : String) -> PackedStringArray:
	var regex := RegEx.new()
	regex.compile("\\s+")
	text = regex.sub(text, " ", true)
	return text.split(" ")
