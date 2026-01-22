extends RichTextLabel

class_name FullText

var _full_text : String
static var _maximum_lines : int = -1
var _currently_page_idx : int = -1
var _quant_of_pages : int = 0

static var _font : Font = load("res://fonts/Poppins/Poppins-Light.ttf")
static var _font_size : int = 25
var _paragraph := TextParagraph.new()
static var _paragraph_width : float = 0

var _currently_page_letters : Array[Letter] = []
var _currently_page_words : Array[Word] = []

@onready var _word_button : Button = $WordButton
var _fade_tween : Tween
var _last_word_in_button : Word
var _currently_word_in_button : Word

@onready var _pages_text : RichTextLabel = $"../Bottom/HBoxContainer/Pages"
@onready var _left_page_button : Button = $"../Bottom/HBoxContainer/LeftPage"
@onready var _right_page_button : Button = $"../Bottom/HBoxContainer/RightPage"

var _last_size_y : float = 0

signal clicked_on_word(word : String, idx : int)
signal changed_page(page : String)

var _previous_page : String = ""
var _next_page : String = ""

func _ready() -> void:
	add_theme_font_override("normal_font", _font)
	add_theme_font_size_override("normal_font_size", _font_size)
	resized.connect(_resized)
	ReaderThread.calculated_all_pages.connect(_calculated_all_pages)
	ReaderThread.calculated_pages.connect(_calculated_pages)
	ReaderThread.will_calculate_pages.connect(_reset)

func _resized() -> void:
	_paragraph_width = size.x
	_paragraph.width = size.x
	set_full_text(_full_text)
	if size.y != _last_size_y:
		_last_size_y = size.y
		_maximum_lines = _calculate_maximum_lines()

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

func _reset() -> void:
	_full_text = ""
	_currently_page_idx = -1
	_quant_of_pages = 0
	_currently_page_letters.clear()
	_currently_page_words.clear()
	_previous_page = ""
	_next_page = ""
	_pages_text.text = "0/0"

static func get_font() -> Font:
	return _font

static func get_font_size() -> int:
	return _font_size

static func get_paragraph_width() -> float:
	return _paragraph_width

static func get_max_lines() -> int:
	return _maximum_lines

func _calculated_all_pages(_pages : int) -> void:
	if _currently_page_idx < 0:
		set_page(0)

func _calculated_pages(pages : int) -> void:
	_quant_of_pages = pages
	if _currently_page_idx < 0 and _quant_of_pages > 2:
		set_page(0)
	_pages_text.text = str(_currently_page_idx + 1) + "/" + str(_quant_of_pages)
	if _currently_page_idx == 0:
		_left_page_button.disabled = true
	else:
		_left_page_button.disabled = false
	if _currently_page_idx == _quant_of_pages - 1:
		_right_page_button.disabled = true
	else:
		_right_page_button.disabled = false

func set_page(page_idx : int) -> void:
	if page_idx < 0 or page_idx >= _quant_of_pages:
		return

	_pages_text.text = str(page_idx + 1) + "/" + str(_quant_of_pages)

	if page_idx == _currently_page_idx - 1 and not _previous_page.is_empty():
		_next_page = _full_text
		_full_text = _previous_page

		if page_idx - 1 >= 0:
			_previous_page = ReaderThread.get_page_text(page_idx - 1)
		else:
			_previous_page = ""

	elif page_idx == _currently_page_idx + 1 and not _next_page.is_empty():
		_previous_page = _full_text
		_full_text = _next_page

		if page_idx + 1 < _quant_of_pages:
			_next_page = ReaderThread.get_page_text(page_idx + 1)
		else:
			_next_page = ""

	else:
		_full_text = ReaderThread.get_page_text(page_idx)

		if page_idx - 1 >= 0:
			_previous_page = ReaderThread.get_page_text(page_idx - 1)
		else:
			_previous_page = ""

		if page_idx + 1 < _quant_of_pages:
			_next_page = ReaderThread.get_page_text(page_idx + 1)
		else:
			_next_page = ""

	_currently_page_idx = page_idx
	set_full_text(_full_text)
	changed_page.emit(_full_text)

func get_page_index() -> int:
	return _currently_page_idx

func get_previous_page() -> String:
	return _previous_page

func get_current_page() -> String:
	return _full_text

func get_next_page() -> String:
	return _next_page

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
	queue_redraw()

func disable_pages() -> void:
	_pages_text.text = "0/0"
	_left_page_button.disabled = true
	_right_page_button.disabled = true

func _draw() -> void:
	if _full_text.is_empty():
		return
	
	_paragraph.clear()
	_paragraph.add_string(_full_text, _font, _font_size)
	
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
			
			if advance == 0 and character_idx < _full_text.length() and _full_text[character_idx] not in ["\t", "\n"]:
				continue
			
			# get the offset, it may be needed
			#var offset = glyph.get("offset", Vector2.ZERO)
			
			_currently_page_letters.append(Letter.new(Rect2(Vector2(x, y), Vector2(advance, ascent + descent)), _full_text[character_idx], i))
			
			# add the advance to x
			x += advance
			character_idx += 1

		# update y with the ascent and descent of the line
		y += ascent + descent
	
	var word_idx := 0
	var idx := 0
	var _current_word : Word = null

	while idx < _currently_page_letters.size():
		var letter := _currently_page_letters[idx]

		if not Global.is_whitespace(letter.letter):
			if _current_word == null:
				_current_word = Word.new(letter.rect, "", word_idx, letter.line)
				word_idx += 1

			_current_word.word += letter.letter
			_current_word.rect = _current_word.rect.merge(letter.rect)
		else:
			if _current_word != null:
				_currently_page_words.append(_current_word)
				_current_word = null

		idx += 1

	if _current_word != null:
		_currently_page_words.append(_current_word)
	
	# draw the paragraph to this canvas item
	_paragraph.draw(get_canvas_item(), Vector2.ZERO)

func _calculate_maximum_lines() -> int:
	var paragraph := TextParagraph.new()
	paragraph.width = size.x
	paragraph.add_string("P", _font, _font_size)
	
	# Get the primary text server
	var text_server = TextServerManager.get_primary_interface()
	var y = 0.0
	var ascent = 0.0
	var descent = 0.0
	var found_maximum_lines : bool = false
	var maximum_lines = 0
	
	while not found_maximum_lines:
		# for each line
		for i in paragraph.get_line_count():
			maximum_lines += 1
			
			# get the ascent and descent of the line
			ascent = paragraph.get_line_ascent(i)
			descent = paragraph.get_line_descent(i)

			# get the rid of the line
			var line_rid = paragraph.get_line_rid(i)
		
			# get all the glyphs that compose the line
			var glyphs = text_server.shaped_text_get_glyphs(line_rid)

			# for each glyph
			for glyph in glyphs:
				
				if y + ascent + descent >= size.y:
					maximum_lines -= 1
					found_maximum_lines = true
					break

			# update y with the ascent and descent of the line
			y += ascent + descent
			if found_maximum_lines:
				break
	return maximum_lines

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
			idx += Global.split_text_by_space(_full_text).size()
			page_idx += 1
		#print(Global.split_text_by_space(_pages[page_idx]))
		#clicked_on_word.emit(_currently_word_in_button.word, idx + _currently_word_in_button.idx)
		clicked_on_word.emit(_currently_word_in_button.word, _currently_word_in_button.idx)

func _on_left_page_pressed() -> void:
	if _currently_page_idx > 0:
		_currently_page_idx -= 1
		set_page(_currently_page_idx)
		_left_page_button.release_focus()
		_right_page_button.disabled = false
		if _currently_page_idx <= 0:
			_left_page_button.disabled = true

func _on_right_page_pressed() -> void:
	if _currently_page_idx < _quant_of_pages - 1:
		_currently_page_idx += 1
		set_page(_currently_page_idx)
		_right_page_button.release_focus()
		_left_page_button.disabled = false
		if _currently_page_idx >= _quant_of_pages - 1:
			_right_page_button.disabled = true
