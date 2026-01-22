extends MarginContainer

class_name SpeedReader

const MIN_WORDS_PER_MINUTE : float = 1
const MAX_WORDS_PER_MINUTE : float = 2000
const PUNCTUATION_DELAY : float = 0.5

const PUNCTUATIONS : String = ".,:;!?"
const IGNORED_CHARACTERS : String = PUNCTUATIONS + "'´`"

@onready var _full_text : FullText = $TextContainer/VBoxContainer/FullText
@onready var _player : Player = $Player

@onready var _timer : Timer = $Timer

var _font : Font = load("res://fonts/Poppins/Poppins-Light.ttf")
var _font_size : int = 100
var _paragraph = TextParagraph.new()

#var _text : String
var _words : PackedStringArray
var _currently_word_idx : int = -1
var _words_per_minute : float = 250
var _currently_words_per_minute : float = 250
var _current_word : String = ""

var _is_paused : bool = true

var _current_page : String = ""

func _ready() -> void:
	_player.set_wpm(250)
	
	_full_text.clicked_on_word.connect(_full_text_clicked_on_word)
	
	_font_size = 50
	
	_paragraph.width = 600
	
	_full_text.changed_page.connect(_get_page)
	
	_player.go_backward.connect(_player_go_backward)
	_player.play.connect(_player_play)
	_player.go_forward.connect(_player_go_forward)
	_player.wpm_changed.connect(_player_wpm_changed)
	
	ReaderThread.will_calculate_pages.connect(_reset)

func _reset() -> void:
	_current_page = ""
	_current_word = ""
	_currently_word_idx = -1
	queue_redraw()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_player.set_paused(not _is_paused)

func _player_go_backward() -> void: ## TODO WARNING BECAFERUL NOTE BUG
	if _currently_word_idx - 1 > 0 and _currently_word_idx - 1 < _words.size():
		_currently_word_idx -= 1
		_set_current_word(_currently_word_idx)
	if _currently_word_idx - 1 == 0:
		_currently_word_idx -= 1
		_full_text.set_page(_full_text.get_page_index() - 1)

func _player_play(can_play : bool) -> void:
	if can_play:
		play()
	else:
		stop()

func _player_go_forward() -> void: ## TODO WARNING BECAFERUL NOTE BUG
	if _words.size() > 0 and _currently_word_idx + 1 < _words.size():
		_currently_word_idx += 1
		_set_current_word(_currently_word_idx)
	if _currently_word_idx + 1 >= _words.size() - 1:
		_currently_word_idx += 1
		_full_text.set_page(_full_text.get_page_index() + 1)

func _player_wpm_changed(wpm : int) -> void:
	_words_per_minute = wpm
	_currently_words_per_minute = wpm

#func set_text(text : String) -> void:
	#_full_text.set_full_text(text.strip_edges())
	#_words = Global.split_text_by_space(_full_text.get_full_text())
	#_set_current_word(0)
	#_currently_word_idx = -1

func set_words_per_minute(wpm : float) -> void:
	_words_per_minute = clampf(wpm, MIN_WORDS_PER_MINUTE, MAX_WORDS_PER_MINUTE)
	_currently_words_per_minute = _words_per_minute

func play() -> void:
	if _current_page.is_empty():
		_player.set_paused(true)
		return
	_is_paused = false
	while not _is_paused:
		if _currently_word_idx >= _words.size():
			return
		_currently_word_idx += 1
		_set_current_word(_currently_word_idx)
		if _words[_currently_word_idx][-1] in PUNCTUATIONS:
			_currently_words_per_minute = _words_per_minute - _words_per_minute * PUNCTUATION_DELAY
		else:
			_currently_words_per_minute = _words_per_minute
		_timer.start(60 / _currently_words_per_minute)
		await _timer.timeout
		if _currently_word_idx >= _words.size() - 1:
			if not _full_text.get_next_page().is_empty():
				_full_text.set_page(_full_text.get_page_index() + 1)
			else:
				_player.set_paused(true)
				return

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
