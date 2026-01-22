extends Node

var _thread := Thread.new()

var _file_path : String
var _font : Font
var _font_size : int
var _max_lines : int
var _width : float

var _current_pages_calculated : int = 0

var _pages_position_in_file : PackedInt64Array = []

var _force_to_end : bool = false

signal will_calculate_pages
signal calculated_pages(pages : int)
signal calculated_all_pages(pages : int) ## BASICALLY TELLS THAT THE PROCESS ENDED
signal ended_by_force

func calculate_pages(file_path : String, font : Font, font_size : int, width : float, max_lines : int) -> void:
	if _thread.is_started():
		return
	_file_path = file_path
	_font = font
	_font_size = font_size
	_width = width
	_max_lines = max_lines
	will_calculate_pages.emit()
	_thread.start(_calculate_pages)

func _ended() -> void:
	_thread.wait_to_finish()
	if _force_to_end:
		_force_to_end = false
		ended_by_force.emit()

func _calculate_pages() -> void:
	if not FileAccess.file_exists(_file_path):
		return

	var paragraph := TextParagraph.new()
	paragraph.width = _width

	var file := FileAccess.open(_file_path, FileAccess.READ)

	_pages_position_in_file.clear()
	_pages_position_in_file.append(0)
	_current_pages_calculated = 1

	#var pages : Array[String] = []
	var page_text := ""

	var byte_offset := 0
	var word_start_offset := byte_offset

	var last_remaining_word : String = ""
	
	var check_for_new_page : bool = false

	var word : String = ""

	var next_char : Dictionary = {}

	while not file.eof_reached():
		if _force_to_end:
			file.close()
			_ended.call_deferred()
			return
		
		var current_char : Dictionary
		if next_char.is_empty():
			current_char = read_utf8_char(file)
		else:
			current_char = next_char
			next_char = read_utf8_char(file)
		
		if current_char.is_empty():
			break
		
		if not last_remaining_word.is_empty():
			paragraph.clear()
			paragraph.add_string(page_text + last_remaining_word, _font, _font_size)
			#byte_offset += word.to_utf8_buffer().size() ## WARNING IS THIS REALLY NEEDED?
			if paragraph.get_line_count() > _max_lines:
				_pages_position_in_file.append(word_start_offset)
				#pages.append(page_text)
				page_text = ""
				_current_pages_calculated += 1
				calculated_pages.emit.call_deferred(_current_pages_calculated)
			else:
				page_text += last_remaining_word
			last_remaining_word = ""
			
		var has_next_character = not next_char.is_empty()
		if word.is_empty():
			word_start_offset = byte_offset
		if Global.is_whitespace(current_char["char"]):
			word += current_char["char"]
			check_for_new_page = true
		else:
			word += current_char["char"]
			check_for_new_page = has_next_character and Global.is_whitespace(next_char["char"])
			
		if check_for_new_page:
			paragraph.clear()
			paragraph.add_string(page_text + word, _font, _font_size)
			byte_offset += word.to_utf8_buffer().size()
			if paragraph.get_line_count() > _max_lines:
				#pages.append(page_text)
				page_text = ""
				last_remaining_word = word
				_pages_position_in_file.append(word_start_offset)
				word = ""
				_current_pages_calculated += 1
				calculated_pages.emit.call_deferred(_current_pages_calculated)
			else:
				page_text += word
				word = ""
	
	calculated_pages.emit.call_deferred(_current_pages_calculated)
	calculated_all_pages.emit.call_deferred(_current_pages_calculated)
	
	file.close()
	
	_ended.call_deferred()
	
	#print(_pages_position_in_file)
	#
	#for page in pages:
		#print(page)
		#print("---------------------------------------------")
	#for i in _pages_position_in_file.size():
		#print(get_page_text(i))
		#print("---------------------------------------------")

func read_utf8_char(file : FileAccess) -> Dictionary:
	if file.eof_reached():
		return {}

	var start_pos := file.get_position()
	var first_byte := file.get_8()

	var bytes := PackedByteArray([first_byte])

	var needed := 0
	if first_byte & 0b10000000 == 0:
		needed = 0
	elif first_byte & 0b11100000 == 0b11000000:
		needed = 1
	elif first_byte & 0b11110000 == 0b11100000:
		needed = 2
	elif first_byte & 0b11111000 == 0b11110000:
		needed = 3
	else:
		# byte inválido UTF-8
		return {
			"char": "�",
			"start": start_pos,
			"end": file.get_position()
		}

	for i in range(needed):
		if file.eof_reached():
			break
		bytes.append(file.get_8())

	var character := bytes.get_string_from_utf8()
	var end_pos := file.get_position()

	return {
		"char": character,
		"start": start_pos,
		"end": end_pos
	}

func get_page_text(page_index : int) -> String:
	var file := FileAccess.open(_file_path, FileAccess.READ)

	var start := _pages_position_in_file[page_index]
	var end : int

	if page_index < _pages_position_in_file.size() - 1:
		end = _pages_position_in_file[page_index + 1]
	else:
		end = file.get_length()

	file.seek(start)
	var size := end - start

	var bytes := file.get_buffer(size)
	file.close()

	return bytes.get_string_from_utf8()

func get_total_of_pages() -> int:
	return _current_pages_calculated

func is_calculating_pages() -> bool:
	return _thread.is_started()

func force_to_end() -> void:
	_force_to_end = true
