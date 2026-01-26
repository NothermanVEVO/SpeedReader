extends RichTextLabel

class_name FullText

var _full_text : String
static var _maximum_lines : int = -1
static var _maximum_words : int = -1
var _currently_page_idx : int = -1
var _quant_of_pages : int = 0

static var _font : Font = load("res://fonts/Poppins/Poppins-Light.ttf")
static var _font_size : int = 25
var _paragraph := TextParagraph.new()
static var _paragraph_width : float = 0

var _currently_page_letters : Array[Letter] = []
var _currently_page_words : Array[Word] = []

@onready var _word_button : Button = $WordButton
var _additional_word_buttons : Array[Button] = []

var _fade_tween : Tween
var _last_word_in_button : Word
var _currently_word_in_button : Word

@onready var _left_page_button : Button = $"../../../Bottom/FlowContainer/LeftPage"
@onready var _page_spin_box : SpinBox = $"../../../Bottom/FlowContainer/HBoxContainer/PageSpinBox"
@onready var _pages_text : RichTextLabel = $"../../../Bottom/FlowContainer/HBoxContainer/PagesText"
@onready var _right_page_button : Button = $"../../../Bottom/FlowContainer/RightPage"

@onready var _text_container : TextContainer = $"../../../.."

var _last_size := Vector2.ZERO

signal clicked_on_word(word : String, idx : int)
signal changed_page(page : String)

var _previous_page : String = ""
var _next_page : String = ""

var _last_word_byte_pos_in_focus : int = -1
var _page_idx_of_last_word : int = -1
var _found_word_byte_pos : bool = true

var _word_in_focus : Word

var _after_next_page_to_set : int = -1
var _next_page_to_set : int = -1

func _ready() -> void:
	add_theme_font_override("normal_font", _font)
	add_theme_font_size_override("normal_font_size", _font_size)
	
	_page_spin_box.get_line_edit().text_submitted.connect(_remove_page_line_edit_focus)
	
	resized.connect(_resized)
	
	ReaderThread.calculated_all_pages.connect(_calculated_all_pages)
	ReaderThread.calculated_pages.connect(_calculated_pages)
	ReaderThread.will_calculate_pages.connect(_reset)
	
	Global.changed_theme.connect(_changed_theme)
	
	_text_container.will_open_diferent_file.connect(_will_open_diferent_file)

func _will_open_diferent_file() -> void:
	_last_word_byte_pos_in_focus = -1
	_found_word_byte_pos = true

func _changed_theme(_theme : Global.Themes) -> void:
	_word_button.modulate = _get_word_button_color()
	queue_redraw()

func _resized() -> void:
	set_full_text(_full_text)
	if size != _last_size:
		_last_size = size
		_paragraph_width = size.x
		_paragraph.width = size.x
		_maximum_lines = _calculate_maximum_lines()
		_maximum_words = _calculate_maximum_words()
		if _text_container.can_reopen_file():
			if _word_in_focus:
				var page_words : Array[Dictionary] = ReaderThread.get_page_words_with_positions(_currently_page_idx)
				_found_word_byte_pos = not page_words.is_empty()
				if page_words:
					var idx : int = _word_in_focus.idx if _word_in_focus.idx < page_words.size() else 0
					_last_word_byte_pos_in_focus = page_words[idx]["pos"]
				else:
					_last_word_byte_pos_in_focus = -1
				_word_in_focus = null
			_text_container.reopen_file()

func set_last_word_byte_pos_in_focus(last_word_byte_pos_in_focus : int) -> void:
	_last_word_byte_pos_in_focus = last_word_byte_pos_in_focus

func get_page_n_word_idx() -> int:
	var page_words : Array[Dictionary] = ReaderThread.get_page_words_with_positions(_currently_page_idx)
	
	var idx : int = _word_in_focus.idx if _word_in_focus and page_words and _word_in_focus.idx < page_words.size() else 0
	
	return page_words[idx]["pos"] if page_words else 0

func _physics_process(_delta: float) -> void:
	if not visible:
		return
	
	var _found_mouse_in_word : bool = false
	for word in _currently_page_words:
		for rect in word.get_word_rects():
			if rect.has_point(get_local_mouse_position()):
				_set_word_button(word)
				_found_mouse_in_word = true
				break
		if _found_mouse_in_word:
			break
	if not _found_mouse_in_word and _word_button.modulate.a == 0.75:
		_fade_out_button()
		_last_word_in_button = null

func _reset() -> void:
	_full_text = ""
	#_last_word_idx_in_focus = -1
	_currently_page_idx = -1
	_quant_of_pages = 0
	_clear_letter_n_words()
	_previous_page = ""
	_next_page = ""
	_pages_text.text = "/1"
	_page_spin_box.value = 1
	_page_spin_box.max_value = 1

static func get_font() -> Font:
	return _font

static func get_font_size() -> int:
	return _font_size

static func get_paragraph_width() -> float:
	return _paragraph_width

static func get_max_lines() -> int:
	return _maximum_lines

static func get_max_words() -> int:
	return _maximum_words

func _calculated_all_pages(_pages : int) -> void:
	if _currently_page_idx < 0:
		set_page(0)

func _process(_delta: float) -> void:
	if _next_page_to_set >= 0:
		set_page(_next_page_to_set)
		await get_tree().create_timer(0.1).timeout
		_next_page_to_set = _after_next_page_to_set
		_after_next_page_to_set = -1

func _calculated_pages(pages : int) -> void:
	_quant_of_pages = pages
	
	_page_spin_box.max_value = _quant_of_pages
	
	if not _found_word_byte_pos:
		var page : int = _quant_of_pages - 2
		if _next_page_to_set < 0:
			_next_page_to_set = page
		elif page > _after_next_page_to_set:
			_after_next_page_to_set = page
	
	if _last_word_byte_pos_in_focus >= 0:
		if _page_idx_of_last_word < 0:
			_page_idx_of_last_word = ReaderThread.get_page_index_by_file_pos(_last_word_byte_pos_in_focus)
			var page : int = _quant_of_pages - 2
			if _next_page_to_set < 0:
				_next_page_to_set = page
			elif page > _after_next_page_to_set:
				_after_next_page_to_set = page
		elif _quant_of_pages - 1 < _page_idx_of_last_word:
			var page : int = _quant_of_pages - 2
			if _next_page_to_set < 0:
				_next_page_to_set = page
			if page > _after_next_page_to_set:
				_after_next_page_to_set = page
		else:
			_next_page_to_set = -1
			_after_next_page_to_set = -1
			set_page(_page_idx_of_last_word)
			var idx := ReaderThread.get_word_idx_in_page_by_pos(_page_idx_of_last_word, _last_word_byte_pos_in_focus)
			clicked_on_word.emit("", idx)
			set_word_idx_in_focus(idx)
			_last_word_byte_pos_in_focus = -1
			_page_idx_of_last_word = -1
	
	if _currently_page_idx < 0 and _quant_of_pages > 2: ## WARNING IS IT RIGHT?
		set_page(0)
	
	_page_spin_box.value = _currently_page_idx + 1
	_pages_text.text = "/" + str(_quant_of_pages)
	if _currently_page_idx == 0:
		_left_page_button.disabled = true
	else:
		_left_page_button.disabled = false
	if _currently_page_idx == _quant_of_pages - 1:
		_right_page_button.disabled = true
	else:
		_right_page_button.disabled = false

func go_to_next_non_blank_page() -> void:
	var page : String = " "
	while Global.is_only_whitespace(page) and _currently_page_idx + 1 < _quant_of_pages:
		_currently_page_idx += 1
		page = ReaderThread.get_page_text(_currently_page_idx)
	
	set_page(_currently_page_idx)

func set_page(page_idx : int) -> void:
	if page_idx < 0 or page_idx >= _quant_of_pages:
		return

	#_page_spin_box.value = page_idx + 1
	#_pages_text.text = "/" + str(_quant_of_pages)

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

	_left_page_button.disabled = false
	_right_page_button.disabled = false

	if page_idx <= 0:
		_left_page_button.disabled = true
	if page_idx >= _quant_of_pages - 1:
		_right_page_button.disabled = true

	_currently_page_idx = page_idx
	
	_page_spin_box.value = _currently_page_idx + 1
	_pages_text.text = "/" + str(_quant_of_pages)
	
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
	_last_word_in_button = _currently_word_in_button
	
	for button in _additional_word_buttons:
		button.pressed.disconnect(_on_word_button_pressed)
		remove_child(button)
		button.queue_free()
	_additional_word_buttons.clear()
	
	var word_rects : Array[Rect2] = _currently_word_in_button.get_word_rects()
	
	if word_rects.is_empty():
		return
	
	_word_button.position = word_rects[0].position
	_word_button.size = word_rects[0].size
	
	for i in range(1, word_rects.size()):
		var button := Button.new()
		add_child(button)
		_additional_word_buttons.append(button)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.focus_mode = Control.FOCUS_NONE
		button.modulate = _get_word_button_color()
		button.show_behind_parent = true
		button.visible = false
		button.pressed.connect(_on_word_button_pressed)
		button.position = word_rects[i].position
		button.size = word_rects[i].size
	
	_fade_in_button()

func _fade_in_button(duration : float = 0.15) -> void:
	if _fade_tween:
		_fade_tween.kill()

	_word_button.visible = true
	_word_button.modulate.a = 0.0
	
	for button in _additional_word_buttons:
		button.visible = true
		button.modulate.a = 0.0

	_fade_tween = create_tween()
	_fade_tween.parallel().tween_property(
		_word_button,
		"modulate:a",
		0.75,
		duration
	)
	
	for button in _additional_word_buttons:
		_fade_tween.parallel().tween_property(
		button,
		"modulate:a",
		0.75,
		duration
		)

func _fade_out_button(duration : float = 0.1) -> void:
	if _fade_tween:
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.parallel().tween_property(
		_word_button,
		"modulate:a",
		0.0,
		duration
	)
	
	for button in _additional_word_buttons:
		_fade_tween.parallel().tween_property(
		button,
		"modulate:a",
		0.0,
		duration
		)

	_fade_tween.finished.connect(func():
		_word_button.visible = false
		for button in _additional_word_buttons:
			button.visible = false
	)

func set_full_text(full_text : String) -> void:
	_full_text = full_text
	_calculate_words()

func disable_pages() -> void:
	_pages_text.text = "0/0"
	_left_page_button.disabled = true
	_right_page_button.disabled = true

## MAKES THE GARBAGE COLLECTOR TRULY COLLECTS THIS || PREVENTS MEMORY LEAK
func _clear_letter_n_words() -> void:
	for letter in _currently_page_letters:
		letter.word_parent = null
		letter = null
	
	for word in _currently_page_words:
		word = null
	
	_currently_page_letters.clear()
	_currently_page_words.clear()

func _calculate_words() -> void:
	#if _full_text.is_empty():
		#return
	
	_paragraph.clear()
	_paragraph.add_string(_full_text, _font, _font_size)
	
	_clear_letter_n_words()
	
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
				_current_word = Word.new([], word_idx)
				word_idx += 1

			_current_word.letters.append(letter)
			letter.word_parent = _current_word
		else:
			if _current_word != null:
				_currently_page_words.append(_current_word)
				_current_word = null

		idx += 1

	if _current_word != null:
		_currently_page_words.append(_current_word)

func set_word_idx_in_focus(idx : int) -> void:
	if visible:
		queue_redraw()
	
	if idx < 0 or idx >= _currently_page_words.size():
		return
	
	#_last_word_idx_in_focus = idx
	
	if _word_in_focus:
		_word_in_focus.in_focus = false
	
	_word_in_focus = _currently_page_words[idx]
	_word_in_focus.in_focus = true

func _draw() -> void:
	#if _full_text.is_empty():
		#return
	
	# draw the paragraph to this canvas item
	#_paragraph.draw(get_canvas_item(), Vector2.ZERO)
	
	var theme_text_color : Color = Global.get_theme_text_color()
	
	for letter in _currently_page_letters:
		var pos : Vector2 = letter.rect.position
		pos.y += _font_size
		var color : Color = theme_text_color if letter.word_parent and not letter.word_parent.in_focus else Color.RED
		draw_string(_font, pos, letter.letter, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, color)

func _calculate_maximum_words() -> int:
	var paragraph := TextParagraph.new()
	paragraph.width = size.x
	
	@warning_ignore("shadowed_variable_base_class")
	var text := ""
	
	# Get the primary text server
	var text_server = TextServerManager.get_primary_interface()
	var jumped_line : bool = false
	
	while not jumped_line:
		
		text += "|"
		paragraph.clear()
		paragraph.add_string(text, _font, _font_size)
		
		# for each line
		for i in paragraph.get_line_count():
			var x = 0.0

			# get the rid of the line
			var line_rid = paragraph.get_line_rid(i)
		
			# get all the glyphs that compose the line
			var glyphs = text_server.shaped_text_get_glyphs(line_rid)

			# for each glyph
			for glyph in glyphs:
				var advance : float = glyph.get("advance", 0)
				if x + advance >= paragraph.width:
					jumped_line = true
					break
				x += advance

			if jumped_line:
				break
	
	return (text.length() - 1) * _maximum_lines

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
	var word_parent : Word
	
	@warning_ignore("shadowed_variable")
	func _init(rect : Rect2, letter : String, line : int) -> void:
		self.rect = rect
		self.letter = letter
		self.line = line

class Word:
	var idx : int
	var letters : Array[Letter]
	var in_focus : bool = false
	
	@warning_ignore("shadowed_variable")
	func _init(letters : Array[Letter], idx : int) -> void:
		self.letters = letters
		self.idx = idx
	
	func get_word_rects() -> Array[Rect2]:
		var rects : Array[Rect2] = []
		
		if letters.is_empty():
			return []
		
		var rect : Rect2 = letters[0].rect
		var last_line : int = letters[0].line
		
		for i in range(1, letters.size()):
			if letters[i].line > last_line:
				rects.append(rect)
				rect = letters[i].rect
				last_line = letters[i].line
			else:
				rect = rect.merge(letters[i].rect)
		
		rects.append(rect)
		
		return rects

	func get_word() -> String:
		var word := ""
		
		for letter in letters:
			word += letter.letter
		
		return word

func _get_word_button_color() -> Color:
	match Global.get_theme_type():
		Global.Themes.DARK:
			return Color(0.0, 2.319, 2.321, 0.0)
		Global.Themes.WHITE:
			return Color(0.0, 0.88, 0.88, 0.0)
	
	return Color(0.0, 0.0, 0.0, 0.0)

func _on_word_button_pressed() -> void:
	if _word_button.modulate.a > 0:
		var page_idx : int = 0
		while page_idx < _currently_page_idx:
			page_idx += 1
		clicked_on_word.emit(_currently_word_in_button.get_word(), _currently_word_in_button.idx)

func _on_left_page_pressed() -> void:
	if _currently_page_idx > 0:
		_currently_page_idx -= 1
		set_page(_currently_page_idx)
		_left_page_button.release_focus()

func _on_right_page_pressed() -> void:
	if _currently_page_idx < _quant_of_pages - 1:
		_currently_page_idx += 1
		set_page(_currently_page_idx)
		_right_page_button.release_focus()

func _on_page_spin_box_value_changed(value: float) -> void:
	@warning_ignore("narrowing_conversion")
	set_page(value - 1)

func is_in_focus() -> bool:
	return _page_spin_box.get_line_edit().has_focus()

func _remove_page_line_edit_focus(_new_text: String) -> void:
	await get_tree().create_timer(0.1).timeout
	_page_spin_box.get_line_edit().release_focus()
