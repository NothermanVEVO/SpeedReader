extends MarginContainer

const MIN_WORDS_PER_MINUTE : float = 0.01
const MAX_WORDS_PER_MINUTE : float = 10000
const PUNCTUATION_DELAY : float = 0.5

const PUNCTUATIONS : String = ".,:;!?"
const IGNORED_CHARACTERS : String = PUNCTUATIONS + "'´`"

@onready var _full_text : FullText = $TextContainer/VBoxContainer/FullText
@onready var _timer : Timer = $Timer
@onready var _text_container : TextContainer = $TextContainer

var _font : Font = load("res://fonts/Poppins/Poppins-Light.ttf")
var _font_size : int = 100
var _paragraph = TextParagraph.new()

#var _text : String
var _words : PackedStringArray
var _currently_word_idx : int = -1
var _words_per_minute : float = 250
var _currently_words_per_minute : float = 250
var _current_word : String = ""

var _last_word_before_editing : String = ""

var _is_paused : bool = true

var _current_page : String = ""
var _next_page : String = ""

func _ready() -> void:
	_full_text.clicked_on_word.connect(_full_text_clicked_on_word)

	queue_redraw()
	
	_font_size = 50
	
	_paragraph.width = 600
	
	#_text_container.editing_text.connect(_is_editing_text)
	_full_text.changed_page.connect(_get_page)

func _reset() -> void:
	_last_word_before_editing = _current_word
	_current_word = ""
	queue_redraw()

#func _is_editing_text(is_editing : bool) -> void:
	#if is_editing:
		#_reset()
	#else:
		#set_text(_text_container.get_text())

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and not _text_container.is_editing():
		if _is_paused:
			play()
		else:
			stop()

#func set_text(text : String) -> void:
	#_full_text.set_full_text(text.strip_edges())
	#_words = Global.split_text_by_space(_full_text.get_full_text())
	#_set_current_word(0)
	#_currently_word_idx = -1

func set_words_per_minute(wpm : float) -> void:
	_words_per_minute = clampf(wpm, MIN_WORDS_PER_MINUTE, MAX_WORDS_PER_MINUTE)
	_currently_words_per_minute = _words_per_minute

func play() -> void:
	if _full_text.get_full_text().strip_edges().is_empty():
		return
	_is_paused = false
	while not _is_paused:
		_currently_word_idx += 1
		if _currently_word_idx >= _words.size():
			return
		_set_current_word(_currently_word_idx)
		if _words[_currently_word_idx][-1] in PUNCTUATIONS:
			_currently_words_per_minute = _words_per_minute - _words_per_minute * PUNCTUATION_DELAY
		else:
			_currently_words_per_minute = _words_per_minute
		#print(_currently_words_per_minute / 60)
		_timer.start(60 / _currently_words_per_minute)
		await _timer.timeout
		if _text_container.is_editing():
			stop()

func stop() -> void:
	if not _is_paused:
		@warning_ignore("narrowing_conversion")
		_currently_word_idx = clampi(_currently_word_idx - 1, -1, 9223372036854775807)
		_is_paused = true

func _set_current_word(idx : int) -> void:
	_current_word = _words[idx].strip_edges()
	queue_redraw()

func _get_page(page : String) -> void:
	_current_page = page
	_words.clear()
	_words = Global.split_text_by_space(_current_page)
	if _words.is_empty() and not _full_text.get_next_page().is_empty():
		_full_text.set_page(_full_text.get_page_index() + 1)
	else:
		_set_current_word(0)
		_currently_word_idx = -1

#@warning_ignore("shadowed_variable_base_class")
#func _get_middle_idx(size : int) -> int:
	#if size == 1:
		#return 0
	#var idx : int = roundi(size / 2.0 - 1)
	#if size % 2 == 0:
		#return idx + 1
	#return idx

#@warning_ignore("shadowed_variable_base_class")
#func _get_middle_idx(size : int) -> int:
	#if size == 1:
		#return 0
	#elif size < 8:
		#return 1
	#else:
		#return 2

func _get_middle_idx(_size : int) -> int:
	return 0

#func _get_middle_idx(_size : int) -> int:
	#if _size == 1:
		#return 0
	#else:
		#return 1

func _get_middle_word_idx(word : String) -> int:
	var sub : int = 0
	for letter in word:
		if letter in IGNORED_CHARACTERS:
			sub += 1
	var new_size := word.length() - sub
	if new_size < 0:
		return 0
	var middle : int = _get_middle_idx(new_size)
	return middle

## https://www.reddit.com/r/godot/comments/1987awg/how_to_get_the_world_position_of_a/
func _draw() -> void:
	if not _current_word:
		return
	
	_paragraph.clear()
	_paragraph.add_string(_current_word, _font, _font_size)
	
	# Get the primary text server
	var text_server = TextServerManager.get_primary_interface()
	var x = 0.0
	var y = 0.0
	var ascent = 0.0
	var descent = 0.0
	# reset x
	x = 0.0
	# get the ascent and descent of the line
	ascent = _paragraph.get_line_ascent(0)
	descent = _paragraph.get_line_descent(0)

	# get the rid of the line
	var line_rid = _paragraph.get_line_rid(0)
	
	# get all the glyphs that compose the line
	var glyphs = text_server.shaped_text_get_glyphs(line_rid)

	var middle_glyph_idx : int = _get_middle_word_idx(_current_word)
	var center_letter_position_x : float

	var _text_letters : Array[Letter] = []

	var ghost_quant : int = 0

	# for each glyph
	for i in glyphs.size():
		# get the advance (how much the we need to move x)
		var advance = glyphs[i].get("advance", 0)
		
		if advance == 0:
			ghost_quant += 1
			continue
		
		# get the offset, it may be needed
		#var offset = glyphs[i].get("offset", Vector2.ZERO)
		
		## draw a red rect surrounding the glyph
		#draw_rect(Rect2(Vector2(x + get_viewport_rect().size.x / 2, y), Vector2(advance, ascent + descent)), Color.RED, false)
		_text_letters.append(Letter.new(Rect2(Vector2(x + size.x / 2, _font_size), Vector2(advance, ascent + descent)), _current_word[i - ghost_quant]))
		
		if i == middle_glyph_idx:
			center_letter_position_x = x + size.x / 2 + (advance / 2)
		
		# add the advance to x
		x += advance

	# update y with the ascent and descent of the line
	y += ascent + descent

	var center_position_x : float = size.x / 2

	for i in _text_letters.size():
		_text_letters[i].rect.position.x -= center_letter_position_x - center_position_x
		_text_letters[i].rect.position.y = size.y / 2.0 + _font_size / 4.0
		if i == middle_glyph_idx:
			draw_string(_font, _text_letters[i].rect.position, _text_letters[i].letter, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, Color.RED)
		else:
			draw_string(_font, _text_letters[i].rect.position, _text_letters[i].letter, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, Color.WHITE)

func _full_text_clicked_on_word(_word : String, idx : int) -> void:
	_set_current_word(idx)
	_currently_word_idx = idx
	stop()

class Letter:
	var rect : Rect2
	var letter : String
	
	@warning_ignore("shadowed_variable")
	func _init(rect : Rect2, letter : String) -> void:
		self.rect = rect
		self.letter = letter
