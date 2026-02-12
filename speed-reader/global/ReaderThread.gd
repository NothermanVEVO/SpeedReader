extends Node

var _thread := Thread.new()

var _file_path : String
var _font : Font
var _font_size : int
var _max_lines : int
var _max_words : int
var _width : float

var _current_pages_calculated : int = 0
var _calculated_all_pages : bool = false

var _pages_position_in_file : PackedInt64Array = []

var _force_to_end : bool = false

signal will_calculate_pages
signal calculated_pages(pages : int)
signal calculated_all_pages(pages : int) ## BASICALLY YELLS THAT THE PROCESS ENDED
signal ended_by_force

func calculate_pages(file_path : String, font : Font, font_size : int, width : float, max_lines : int, max_words : int) -> void:
	if _thread.is_started():
		return
	_file_path = file_path
	_font = font
	_font_size = font_size
	_width = width
	_max_lines = max_lines
	_max_words = max_words
	will_calculate_pages.emit()
	_calculated_all_pages = false
	_thread.start(_calculate_pages)

func _ended() -> void:
	_thread.wait_to_finish()
	if _force_to_end:
		_force_to_end = false
		ended_by_force.emit()

#func _calculate_pages_test() -> void:
func _calculate_pages() -> void:
	#var start_ms := Time.get_ticks_msec()
	
	if not FileAccess.file_exists(_file_path):
		return

	var paragraph := TextParagraph.new()
	paragraph.width = _width

	var file := FileAccess.open(_file_path, FileAccess.READ)

	_pages_position_in_file.clear()
	_pages_position_in_file.append(0)
	_current_pages_calculated = 1

	var remaining_words : Array[Word] = []

	while not file.eof_reached():
		if _force_to_end:
			file.close()
			_ended.call_deferred()
			return
		
		var words : Array[Word] = get_chunk_of_words(file, remaining_words)
		remaining_words.clear()
		
		var left : int = 0
		var right : int = words.size() - 1
		
		var last_word_in_page : Word = null
		var last_word_pos_array : int = -1
		
		var page_start := _pages_position_in_file[-1]

		while left <= right:
			@warning_ignore("integer_division")
			var mid := (left + right) / 2

			var candidate_end := words[mid].end_byte_pos

			if _fits_range(paragraph, file, page_start, candidate_end):
				last_word_in_page = words[mid]
				last_word_pos_array = mid
				left = mid + 1
			else:
				right = mid - 1

		if last_word_pos_array < words.size() - 1:
			remaining_words = words.slice(last_word_pos_array + 1)
		
		if last_word_in_page:
			_pages_position_in_file.append(last_word_in_page.end_byte_pos - 1)
			file.seek(last_word_in_page.end_byte_pos)
			_current_pages_calculated += 1
			calculated_pages.emit.call_deferred(_current_pages_calculated)
	
	calculated_pages.emit.call_deferred(_current_pages_calculated)
	calculated_all_pages.emit.call_deferred(_current_pages_calculated)
	
	_calculated_all_pages = true
	
	file.close()
	
	#var end_ms := Time.get_ticks_msec()
	#var elapsed_ms := end_ms - start_ms
	#var elapsed_s := float(elapsed_ms) / 1000.0
#
	#var pages : float = max(_current_pages_calculated - 1, 1)
	#var pages_per_sec : float = float(pages) / max(elapsed_s, 0.001)

	#print("=== CALC PAGES DONE ===")
	#print("Páginas:", pages)
	#print("Tempo:", elapsed_ms, "ms (", elapsed_s, "s )")
	#print("Páginas/s:", pages_per_sec)
	#
	### DEBUG ## TO CHECK IF A PAGE HAS MORE LINES THAN IT SHOULD
	#for i in _pages_position_in_file.size():
		#var text := get_page_text(i)
		#paragraph.clear()
		#paragraph.add_string(text, _font, _font_size)
		#if paragraph.get_line_count() > _max_lines:
			#print(i)
	
	#print("acabou")
	
	_ended.call_deferred()

func _fits_range(paragraph: TextParagraph, file: FileAccess, start: int, end: int) -> bool:
	if end <= start:
		return true

	var old_pos := file.get_position()

	file.seek(start)
	var bytes := file.get_buffer(end - start)
	var text := bytes.get_string_from_utf8()

	paragraph.clear()
	paragraph.add_string(text, _font, _font_size)

	file.seek(old_pos)

	return paragraph.get_line_count() <= _max_lines

#func _calculate_pages() -> void:
	#var start_ms := Time.get_ticks_msec()
	#
	#if not FileAccess.file_exists(_file_path):
		#return
#
	#var paragraph := TextParagraph.new()
	#paragraph.width = _width
#
	#var file := FileAccess.open(_file_path, FileAccess.READ)
#
	#_pages_position_in_file.clear()
	#_pages_position_in_file.append(0)
	#_current_pages_calculated = 1
#
	#var page_text := ""
#
	#var byte_offset := 0
	#var word_start_offset := byte_offset
#
	#var last_remaining_word : String = ""
	#
	#var check_for_new_page : bool = false
#
	#var word : String = ""
#
	#var next_char : Dictionary = {}
#
	#while not file.eof_reached():
		#if _force_to_end:
			#file.close()
			#_ended.call_deferred()
			#return
		#
		#var current_char : Dictionary
		#if next_char.is_empty():
			#current_char = read_utf8_char(file)
		#else:
			#current_char = next_char
			#next_char = read_utf8_char(file)
		#
		#if current_char.is_empty():
			#break
		#
		#if not last_remaining_word.is_empty():
			#paragraph.clear()
			#paragraph.add_string(page_text + last_remaining_word, _font, _font_size)
			#if paragraph.get_line_count() > _max_lines:
				#_pages_position_in_file.append(word_start_offset)
				#page_text = ""
				#_current_pages_calculated += 1
				#calculated_pages.emit.call_deferred(_current_pages_calculated)
			#else:
				#page_text += last_remaining_word
			#last_remaining_word = ""
			#
		#var has_next_character = not next_char.is_empty()
		#if word.is_empty():
			#word_start_offset = byte_offset
		#if Global.is_whitespace(current_char["char"]):
			#word += current_char["char"]
			#check_for_new_page = true
		#else:
			#word += current_char["char"]
			#check_for_new_page = has_next_character and Global.is_whitespace(next_char["char"])
			#
		#if check_for_new_page:
			#paragraph.clear()
			#paragraph.add_string(page_text + word, _font, _font_size)
			#byte_offset += word.to_utf8_buffer().size()
			#if paragraph.get_line_count() > _max_lines:
				#page_text = ""
				#last_remaining_word = word
				#_pages_position_in_file.append(word_start_offset)
				#word = ""
				#_current_pages_calculated += 1
				#calculated_pages.emit.call_deferred(_current_pages_calculated)
			#else:
				#page_text += word
				#word = ""
	#
	#calculated_pages.emit.call_deferred(_current_pages_calculated)
	#calculated_all_pages.emit.call_deferred(_current_pages_calculated)
	#
	#_calculated_all_pages = true
	#
	#file.close()
	#
	#var end_ms := Time.get_ticks_msec()
	#var elapsed_ms := end_ms - start_ms
	#var elapsed_s := float(elapsed_ms) / 1000.0
#
	#var pages : int = max(_current_pages_calculated - 1, 1)
	#var pages_per_sec : float = float(pages) / max(elapsed_s, 0.001)
#
	#print("=== CALC PAGES DONE ===")
	#print("Páginas:", pages)
	#print("Tempo:", elapsed_ms, "ms (", elapsed_s, "s )")
	#print("Páginas/s:", pages_per_sec)
	#
	#_ended.call_deferred()
	
	#_calculate_pages_test()

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

func get_chunk_of_words(file : FileAccess, remaining_words : Array[Word] = []) -> Array[Word]:
	var words : Array[Word] = []
	
	var current_word := Word.new("", -1, -1)
	
	if not remaining_words.is_empty():
		file.seek(remaining_words[-1].end_byte_pos)
		words.append_array(remaining_words)
	
	while not file.eof_reached():
		var current_char := read_utf8_char(file)
		if current_char.is_empty():
			break
		
		#if current_char["char"] == "\r":
			#continue
		
		if current_word.word.is_empty():
			current_word.word += current_char["char"]
			current_word.start_byte_pos = current_char["start"]
			if Global.is_whitespace(current_word.word):
				current_word.end_byte_pos = current_char["end"]
				words.append(current_word)
				current_word = Word.new("", -1, -1)
		else:
			if Global.is_whitespace(current_char["char"]):
				current_word.end_byte_pos = current_char["end"]
				words.append(current_word)
				current_word = Word.new("", -1, -1)
				if words.size() < _max_words:
					words.append(Word.new(current_char["char"], current_char["start"], current_char["end"]))
				else:
					file.seek(current_char["start"])
					return words
			else:
				current_word.end_byte_pos = current_char["end"]
				current_word.word += current_char["char"]
		
		if words.size() == _max_words:
			return words
	
	if not current_word.word.is_empty() and words.size() < _max_words:
		words.append(current_word)
	
	return words

func get_text_from_words(words : Array[Word]) -> String:
	var text : String = ""
	
	for word in words:
		text += word.word
	
	return text

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

func get_page_words_with_positions(page_index: int) -> Array[Dictionary]:
	var file := FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return []

	var start := _pages_position_in_file[page_index]
	var end: int

	if page_index < _pages_position_in_file.size() - 1:
		end = _pages_position_in_file[page_index + 1]
	else:
		end = file.get_length()

	file.seek(start)

	var result: Array[Dictionary] = []

	var current_word := ""
	var current_word_pos := -1
	var inside_word := false

	while file.get_position() < end and not file.eof_reached():
		var ch_data := read_utf8_char(file)
		if ch_data.is_empty():
			break

		var ch: String = ch_data["char"]
		var ch_start: int = ch_data["start"]

		var is_separator := Global.is_whitespace(ch)

		if not is_separator:
			if not inside_word:
				inside_word = true
				current_word_pos = ch_start
				current_word = ""
			current_word += ch
		else:
			if inside_word:
				result.append({
					"word": current_word,
					"pos": current_word_pos
				})
				current_word = ""
				current_word_pos = -1
				inside_word = false

	if inside_word and current_word != "":
		result.append({
			"word": current_word,
			"pos": current_word_pos
		})

	if result.is_empty():
		result.append({
			"word": "",
			"pos": start
		})

	file.close()
	return result

func get_word_idx_in_page_by_pos(page_index: int, word_pos: int) -> int:
	var file := FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return -1

	var start := _pages_position_in_file[page_index]
	var end: int

	if page_index < _pages_position_in_file.size() - 1:
		end = _pages_position_in_file[page_index + 1]
	else:
		end = file.get_length()

	if word_pos < start or word_pos >= end:
		file.close()
		return -1

	file.seek(start)

	var inside_word := false
	var idx := -1

	while file.get_position() < end and not file.eof_reached():
		var ch_data := read_utf8_char(file)
		if ch_data.is_empty():
			break

		var ch: String = ch_data["char"]
		var ch_start: int = ch_data["start"]

		var is_separator := Global.is_whitespace(ch)

		if not is_separator:
			if not inside_word:
				inside_word = true
				idx += 1

				# começou uma palavra nessa posição
				if ch_start == word_pos:
					file.close()
					return idx
		else:
			inside_word = false

	file.close()
	return -1

func get_page_index_by_file_pos(file_pos: int) -> int:
	if _pages_position_in_file.is_empty():
		return -1

	if file_pos < _pages_position_in_file[0]:
		return -1

	var count := _pages_position_in_file.size()

	# Se ainda está calculando páginas, a última ainda não é confiável
	var high := count - 1
	if not _calculated_all_pages:
		if count < 2:
			return -1
		high = count - 2

	var low := 0

	while low <= high:
		@warning_ignore("integer_division")
		var mid := (low + high) / 2

		var start := _pages_position_in_file[mid]

		var next_start: int
		if mid + 1 < count:
			next_start = _pages_position_in_file[mid + 1]
		else:
			@warning_ignore("narrowing_conversion")
			next_start = INF

		if file_pos >= start and file_pos < next_start:
			return mid
		elif file_pos < start:
			high = mid - 1
		else:
			low = mid + 1

	return -1

func get_total_of_pages() -> int:
	return _current_pages_calculated

func is_calculating_pages() -> bool:
	return _thread.is_started()

func force_to_end() -> void:
	_force_to_end = true

func get_file_sha256_stream(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)

	const CHUNK_SIZE := 1024 * 1024 # 1MB por vez

	while not file.eof_reached():
		var chunk := file.get_buffer(CHUNK_SIZE)
		if chunk.size() > 0:
			ctx.update(chunk)

	var hash_bytes := ctx.finish()
	return hash_bytes.hex_encode()

class Word:
	var word : String
	var start_byte_pos : int
	var end_byte_pos : int
	
	@warning_ignore("shadowed_variable")
	func _init(word : String, start_byte_pos : int, end_byte_pos : int) -> void:
		self.word = word
		self.start_byte_pos = start_byte_pos
		self.end_byte_pos = end_byte_pos
	
	func to_text() -> String:
		return "Word: " + str(word) + " | Start byte: " + str(start_byte_pos) + " | End byte: " + str(end_byte_pos)
