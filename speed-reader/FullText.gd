extends RichTextLabel

class_name FullText

var _full_text : String
var _pages : Array[String] = []
var _maximum_lines : int = -1
var _currently_page_idx : int = 0

var _font : Font = load("res://fonts/Poppins/Poppins-Light.ttf")
var _font_size : int = 25
var _paragraph := TextParagraph.new()

var _letters : Array[Letter] = []
var _currently_page_letters : Array[Letter] = []
var _currently_page_words : Array[Word] = []

@onready var _word_button : Button = $WordButton
var _fade_tween : Tween
var _last_word_in_button : Word
var _currently_word_in_button : Word

@onready var _pages_text : RichTextLabel = $"../Bottom/HBoxContainer/Pages"
@onready var _left_page_button : Button = $"../Bottom/HBoxContainer/LeftPage"
@onready var _right_page_button : Button = $"../Bottom/HBoxContainer/RightPage"

signal clicked_on_word(word : String, idx : int)

func _ready() -> void:
	add_theme_font_override("normal_font", _font)
	add_theme_font_size_override("normal_font_size", _font_size)
	resized.connect(_resized)

func _resized() -> void:
	_paragraph.width = size.x
	set_full_text(_full_text)

func _physics_process(_delta: float) -> void:
	var _found_mouse_in_word : bool = false
	for word in _currently_page_words:
		if word.rect.has_point(get_local_mouse_position()):
			_set_word_button(word)
			_found_mouse_in_word = true
			break
	if not _found_mouse_in_word and _word_button.modulate.a == 0.75:
		_fade_out_button()
		_last_word_in_button = null

func _set_word_button(word : Word) -> void:
	_currently_word_in_button = word
	if _last_word_in_button and _last_word_in_button == _currently_word_in_button:
		return
	
	_fade_in_button()
	_word_button.position = _currently_word_in_button.rect.position
	_word_button.size = _currently_word_in_button.rect.size
	
	_last_word_in_button = _currently_word_in_button

func _fade_in_button(duration : float = 0.15) -> void:
	if _fade_tween:
		_fade_tween.kill()

	_word_button.visible = true
	_word_button.modulate.a = 0.0

	_fade_tween = create_tween()
	_fade_tween.tween_property(
		_word_button,
		"modulate:a",
		0.75,
		duration
	)

func _fade_out_button(duration : float = 0.1) -> void:
	if _fade_tween:
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(
		_word_button,
		"modulate:a",
		0.0,
		duration
	)

	_fade_tween.finished.connect(func():
		_word_button.visible = false
	)

func set_full_text(full_text : String) -> void:
	_full_text = full_text
	_calculate_pages(_full_text)
	queue_redraw()

func get_full_text() -> String:
	return _full_text

func disable_pages() -> void:
	_pages_text.text = "0/0"
	_left_page_button.disabled = true
	_right_page_button.disabled = true

func _draw() -> void:
	if not _pages:
		return
	
	_pages_text.text = str(_currently_page_idx + 1) + "/" + str(_pages.size())
	
	_paragraph.clear()
	_paragraph.add_string(_pages[_currently_page_idx], _font, _font_size)
	
	_currently_page_letters.clear()
	_currently_page_words.clear()
	
	# Get the primary text server
	var text_server = TextServerManager.get_primary_interface()
	var x = 0.0
	var y = 0.0
	var ascent = 0.0
	var descent = 0.0
	var character_idx : int = 0
	
	# for each line
	for i in _paragraph.get_line_count():
		# reset x
		x = 0.0
		
		# get the ascent and descent of the line
		ascent = _paragraph.get_line_ascent(i)
		descent = _paragraph.get_line_descent(i)

		# get the rid of the line
		var line_rid = _paragraph.get_line_rid(i)
		
		# get all the glyphs that compose the line
		var glyphs = text_server.shaped_text_get_glyphs(line_rid)

		# for each glyph
		for glyph in glyphs:
			# get the advance (how much the we need to move x)
			var advance = glyph.get("advance", 0)
			
			if advance == 0 and character_idx < _pages[_currently_page_idx].length() and _pages[_currently_page_idx][character_idx] not in ["\t", "\n"]:
				continue
			
			# get the offset, it may be needed
			#var offset = glyph.get("offset", Vector2.ZERO)
			
			_currently_page_letters.append(Letter.new(Rect2(Vector2(x, y), Vector2(advance, ascent + descent)), _pages[_currently_page_idx][character_idx], i))
			
			# add the advance to x
			x += advance
			character_idx += 1

		# update y with the ascent and descent of the line
		y += ascent + descent
	
	var word_idx := 0
	var idx := 0
	var _current_word : Word = null
	var _first_letter_idx := -1

	while idx < _currently_page_letters.size():
		var letter := _currently_page_letters[idx]

		if not _is_whitespace(letter.letter):
			if _current_word == null:
				_current_word = Word.new(letter.rect, "", word_idx, letter.line)
				word_idx += 1
				_first_letter_idx = idx

			_current_word.word += letter.letter
			_current_word.rect = _current_word.rect.merge(letter.rect)
		else:
			if _current_word != null:
				_currently_page_words.append(_current_word)
				_current_word = null
				_first_letter_idx = -1

		idx += 1

	# pega a última palavra (caso não termine com whitespace)
	if _current_word != null:
		_currently_page_words.append(_current_word)
	
	# draw the paragraph to this canvas item
	_paragraph.draw(get_canvas_item(), Vector2.ZERO)

func _calculate_pages(full_text : String) -> void:
	var paragraph := TextParagraph.new()
	paragraph.width = size.x
	paragraph.add_string(full_text, _font, _font_size)
	
	_pages.clear()
	_letters.clear()
	
	# Get the primary text server
	var text_server = TextServerManager.get_primary_interface()
	var x = 0.0
	var y = 0.0
	var ascent = 0.0
	var descent = 0.0
	var character_idx : int = 0
	_maximum_lines = -1
	
	# for each line
	for i in paragraph.get_line_count():
		# reset x
		x = 0.0
		
		# get the ascent and descent of the line
		ascent = paragraph.get_line_ascent(i)
		descent = paragraph.get_line_descent(i)

		# get the rid of the line
		var line_rid = paragraph.get_line_rid(i)
		
		# get all the glyphs that compose the line
		var glyphs = text_server.shaped_text_get_glyphs(line_rid)

		# for each glyph
		for glyph in glyphs:
			# get the advance (how much the we need to move x)
			var advance = glyph.get("advance", 0)
			
			if advance == 0 and character_idx < full_text.length() and full_text[character_idx] not in ["\t", "\n"]:
				continue
			
			# get the offset, it may be needed
			#var offset = glyph.get("offset", Vector2.ZERO)
			
			if _maximum_lines < 0 and y + ascent + descent >= size.y:
				_maximum_lines = i - 1
			_letters.append(Letter.new(Rect2(Vector2(x, y), Vector2(advance, ascent + descent)), full_text[character_idx], i))
			
			
			# add the advance to x
			x += advance
			character_idx += 1

		# update y with the ascent and descent of the line
		y += ascent + descent
	
	if _maximum_lines < 0:
		_maximum_lines = paragraph.get_line_count()
	
	var page : String = ""
	var currently_page : int = 1
	for i in _letters.size():
		if _letters[i].line > _maximum_lines * currently_page:
			currently_page += 1
			_pages.append(page)
			page = "" + _letters[i].letter
		else:
			page += _letters[i].letter
	_letters.clear()
	_pages.append(page)
	_currently_page_idx = 0
	
	_left_page_button.disabled = true
	if _pages.size() > 1:
		_right_page_button.disabled = false
	else:
		_right_page_button.disabled = true

func get_word_index_from_char_idx(_text : String, words : PackedStringArray, char_idx : int) -> int:
	if char_idx < 0 or char_idx >= _text.length():
		return -1

	var running_idx := 0

	for i in words.size():
		var word_len := words[i].length()

		# intervalo da palavra no texto
		var start := running_idx
		var end := running_idx + word_len - 1

		if char_idx >= start and char_idx <= end:
			return i

		# avança: palavra + 1 espaço
		running_idx += word_len + 1

	return -1

#func _get_word_in_idx(idx: int) -> String:
	#if idx < 0 or idx >= text.length():
		#return ""
#
	#if _is_whitespace(text[idx]):
		#return ""
#
	#var start := idx
	#var end := idx
#
	## Anda para trás
	#while start > 0 and not _is_whitespace(text[start - 1]):
		#start -= 1
#
	## Anda para frente
	#while end < text.length() - 1 and not _is_whitespace(text[end + 1]):
		#end += 1
#
	#return text.substr(start, end - start + 1)

func _get_start_idx(idx: int) -> int:
	if idx < 0 or idx >= _full_text.length():
		return -1
	
	if _is_whitespace(_full_text[idx]):
		return -1
	
	var start := idx
	
	# Anda para trás
	while start > 0 and not _is_whitespace(_full_text[start - 1]):
		start -= 1
	
	return start

func _is_whitespace(c: String) -> bool:
	return c == " " or c == "\n" or c == "\t" or c == "\r"

class Letter:
	var rect : Rect2
	var letter : String
	var line : int
	
	@warning_ignore("shadowed_variable")
	func _init(rect : Rect2, letter : String, line : int) -> void:
		self.rect = rect
		self.letter = letter
		self.line = line

class Word:
	var idx : int
	var rect : Rect2
	var word : String
	var line : int
	
	@warning_ignore("shadowed_variable")
	func _init(rect : Rect2, word : String, idx : int, line : int) -> void:
		self.rect = rect
		self.word = word
		self.idx = idx
		self.line = line

func _on_word_button_pressed() -> void:
	if _word_button.modulate.a > 0:
		var idx : int = 0
		var page_idx : int = 0
		while page_idx < _currently_page_idx:
			idx += Global.split_text_by_space(_pages[page_idx]).size() - 1
			page_idx += 1
		clicked_on_word.emit(_currently_word_in_button.word, idx + _currently_word_in_button.idx)

func _on_left_page_pressed() -> void:
	if _currently_page_idx > 0:
		_currently_page_idx -= 1
		queue_redraw()
		_left_page_button.release_focus()
		_right_page_button.disabled = false
		if _currently_page_idx <= 0:
			_left_page_button.disabled = true

func _on_right_page_pressed() -> void:
	if _currently_page_idx < _pages.size() - 1:
		_currently_page_idx += 1
		queue_redraw()
		_right_page_button.release_focus()
		_left_page_button.disabled = false
		if _currently_page_idx >= _pages.size() - 1:
			_right_page_button.disabled = true
