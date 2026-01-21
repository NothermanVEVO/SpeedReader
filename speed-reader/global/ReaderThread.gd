extends Node

var _thread := Thread.new()

var _file_path : String
var _font : Font
var _font_size : int
var _max_lines : int
var _width : float

var _current_pages_calculated : int = 0

var _pages_position_in_file : PackedInt64Array = []

signal calculated_pages(pages : int)
signal calculated_all_pages(pages : int)

func calculate_pages(file_path : String, font : Font, font_size : int, width : float, max_lines : int) -> void:
	_file_path = file_path
	_font = font
	_font_size = font_size
	_width = width
	_max_lines = max_lines
	_thread.start(_calculate_pages)

func _calculate_pages() -> void:
	if not FileAccess.file_exists(_file_path):
		return

	var paragraph := TextParagraph.new()
	paragraph.width = _width

	var file := FileAccess.open(_file_path, FileAccess.READ)

	_pages_position_in_file.clear()
	_pages_position_in_file.append(0)
	_current_pages_calculated = 1

	var page_tokens : Array[String] = []
	var page_text := ""

	var byte_offset := 0

	while not file.eof_reached():
		var line := file.get_line()
		if not file.eof_reached():
			line += "\n"

		var i := 0
		while i < line.length():
			var token := ""
			var token_start_pos := byte_offset

			var c := line[i]

			if c == "\n":
				token = "\n"
				i += 1

			elif Global.is_whitespace(c):
				while i < line.length() and Global.is_whitespace(line[i]) and line[i] != "\n":
					token += line[i]
					i += 1

			else:
				while i < line.length() and not Global.is_whitespace(line[i]):
					token += line[i]
					i += 1

			# bytes do token
			var token_bytes := token.to_utf8_buffer().size()

			# testa token
			page_tokens.append(token)
			var test_text := "".join(page_tokens)

			paragraph.clear()
			paragraph.add_string(test_text, _font, _font_size)

			if paragraph.get_line_count() > _max_lines:
				# remove token testado
				page_tokens.pop_back()

				# nova página começa no token
				_pages_position_in_file.append(token_start_pos)
				_current_pages_calculated += 1
				calculated_pages.emit.call_deferred(_current_pages_calculated)

				# reset página
				page_tokens.clear()
				paragraph.clear()

				# adiciona token na nova página
				page_tokens.append(token)
				page_text = token
				paragraph.add_string(page_text, _font, _font_size)
			else:
				page_text = test_text

			byte_offset += token_bytes

	file.close()
	calculated_pages.emit.call_deferred(_current_pages_calculated)
	calculated_all_pages.emit.call_deferred(_current_pages_calculated)
	
	#print(_pages_position_in_file)
	#for i in _pages_position_in_file.size():
		#print(get_page_text(i))
		#var _paragraph := TextParagraph.new()
		#_paragraph.width = _width
		#_paragraph.add_string(get_page_text(i), _font, _font_size)
		#print(_paragraph.get_line_count())

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
