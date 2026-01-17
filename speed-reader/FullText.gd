extends RichTextLabel

class_name FullText

var _font : Font = load("res://fonts/Poppins/Poppins-Light.ttf")
var _font_size : int = 25
var _paragraph := TextParagraph.new()

var _letters : Array[Letter] = []
var _words : Array[Word] = []

@onready var _word_button : Button = $WordButton
var _fade_tween : Tween
var _last_word_in_button : Word
var _currently_word_in_button : Word

signal clicked_on_word(word : String, idx : int)

func _ready() -> void:
	add_theme_font_override("normal_font", _font)
	add_theme_font_size_override("normal_font_size", _font_size)
	resized.connect(_resized)

func _resized() -> void:
	_paragraph.width = size.x

func _physics_process(_delta: float) -> void:
	var _found_mouse_in_word : bool = false
	for word in _words:
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

func define_text(_text : String) -> void:
	text = _text
	_paragraph.clear()
	_paragraph.add_string(text, _font, _font_size)
	queue_redraw()

func _draw() -> void:
	if not text:
		return
	
	_letters.clear()
	_words.clear()
	
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
			
			# get the offset, it may be needed
			#var offset = glyph.get("offset", Vector2.ZERO)
			
			# draw a red rect surrounding the glyph
			#draw_rect(Rect2(Vector2(x, y), Vector2(advance, ascent + descent)), Color.RED, false)
			_letters.append(Letter.new(Rect2(Vector2(x, y), Vector2(advance, ascent + descent)), text[character_idx]))
			if Rect2(Vector2(x, y), Vector2(advance, ascent + descent)).has_point(get_local_mouse_position()):
				pass
				#print(get_word_index_from_char_idx(text, text.split(" "), character_idx))
				#print(text.split(" ")[get_word_index_from_char_idx(text, text.split(" "), character_idx)])
			
			# add the advance to x
			x += advance
			character_idx += 1

		# update y with the ascent and descent of the line
		y += ascent + descent

	# draw the paragraph to this canvas item
	#_paragraph.draw(get_canvas_item(), Vector2.ZERO)
	var word_idx := 0
	var idx := 0
	var _current_word : Word = null
	var _first_letter_idx := -1

	while idx < _letters.size():
		var letter := _letters[idx]

		if not _is_whitespace(letter.letter):
			if _current_word == null:
				_current_word = Word.new(letter.rect, "", word_idx)
				word_idx += 1
				_first_letter_idx = idx

			_current_word.word += letter.letter
			_current_word.rect = _current_word.rect.merge(letter.rect)
		else:
			if _current_word != null:
				_words.append(_current_word)
				_current_word = null
				_first_letter_idx = -1

		idx += 1

	# pega a última palavra (caso não termine com whitespace)
	if _current_word != null:
		_words.append(_current_word)

	#for word in _words:
		#draw_rect(word.rect, Color.RED, false)
		#print(word.word)

func get_word_index_from_char_idx(_text : String, words : PackedStringArray, char_idx : int) -> int:
	if char_idx < 0 or char_idx >= text.length():
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
	if idx < 0 or idx >= text.length():
		return -1
	
	if _is_whitespace(text[idx]):
		return -1
	
	var start := idx
	
	# Anda para trás
	while start > 0 and not _is_whitespace(text[start - 1]):
		start -= 1
	
	return start

func _is_whitespace(c: String) -> bool:
	return c == " " or c == "\n" or c == "\t" or c == "\r"

class Letter:
	var rect : Rect2
	var letter : String
	
	@warning_ignore("shadowed_variable")
	func _init(rect : Rect2, letter : String) -> void:
		self.rect = rect
		self.letter = letter

class Word:
	var idx : int
	var rect : Rect2
	var word : String
	
	@warning_ignore("shadowed_variable")
	func _init(rect : Rect2, word : String, idx : int) -> void:
		self.rect = rect
		self.word = word
		self.idx = idx

func _on_word_button_pressed() -> void:
	if _word_button.modulate.a > 0:
		clicked_on_word.emit(_currently_word_in_button.word, _currently_word_in_button.idx)
