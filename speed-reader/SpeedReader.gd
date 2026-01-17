extends Control

const MIN_WORDS_PER_MINUTE : float = 0.01
const MAX_WORDS_PER_MINUTE : float = 10000
const PUNCTUATION_DELAY : float = 0.5

const PUNCTUATIONS : String = ".,:;!?"
const IGNORED_CHARACTERS : String = PUNCTUATIONS + "'´`"

@onready var _full_text : FullText = $MarginContainer/FullText
@onready var _timer : Timer = $Timer

var _font : Font = load("res://fonts/Poppins/Poppins-Light.ttf")
var _font_size : int = 100
var _paragraph = TextParagraph.new()

var _text : String
var _words : PackedStringArray
var _currently_word_idx : int = -1
var _words_per_minute : float = 250
var _currently_words_per_minute : float = 250
var _current_word : String = ""

var _is_paused : bool = true

func _ready() -> void:
	_full_text.clicked_on_word.connect(_full_text_clicked_on_word)
	set_text("Oi, oficina, tudo bem com você? Estou testando para ver se está tudo funcionando como o planejado. E então, foi? Você conseguiu ler em uma velocidade maior do que o normal? Isso é algo muito bom para você treinar sua leitura e seu cérebro.")
	#set_text("A tecnologia é uma ponte entre o que imaginamos e o que conseguimos realizar. Por meio dela, transformamos curiosidade em conhecimento, ideias em projetos e sonhos em realidade. Cada linha de código, cada inovação e cada pequeno avanço carregam o poder de mudar vidas, aproximar pessoas e construir um futuro mais criativo, acessível e cheio de possibilidades. E nesse caminho, aprendemos que errar faz parte do processo e que a evolução nasce da persistência. A tecnologia não é apenas feita de máquinas e sistemas, mas de pessoas que ousam tentar, melhorar e compartilhar. Quando usamos o conhecimento para criar com propósito, abrimos espaço para um futuro onde inovação e humanidade caminham juntas. Ela nos convida a enxergar problemas como oportunidades e desafios como pontos de partida. A cada descoberta, ampliamos nossos limites e percebemos que o verdadeiro avanço acontece quando usamos a tecnologia para gerar impacto positivo, inspirar outras pessoas e deixar o mundo um pouco melhor do que encontramos.")
	#set_text("Era madrugada quando a cidade resolveu parar de fazer barulho.
#
#Os semáforos continuavam piscando, mas ninguém passava. As janelas estavam acesas, embora não houvesse silhuetas por trás das cortinas. Até o vento parecia andar de meias, com medo de acordar alguém. Só um lugar seguia vivo: a pequena oficina no fim da rua.
#
#Lá dentro, um rapaz tentava consertar um relógio que não marcava horas — marcava lembranças.
#
#Cada vez que ele girava a engrenagem principal, o ponteiro não avançava no tempo, mas voltava. Um cheiro de café velho surgia, depois o som distante de risadas, depois o gosto metálico de uma despedida que nunca foi dita em voz alta. O relógio era defeituoso assim desde que apareceu, embrulhado em jornal, na porta da oficina, numa noite sem explicação.
#
#O rapaz já tinha tentado de tudo: trocar peças, lubrificar molas, até xingar o objeto em três idiomas diferentes. Nada funcionava. O relógio insistia em lembrar.
#
#Cansado, ele largou as ferramentas e perguntou em voz alta, como quem fala com um gato:
#
#— O que você quer de mim?
#
#O relógio respondeu.
#
#Não com palavras, mas parando exatamente às 03:17.
#
#Naquele instante, a oficina se encheu de algo que não era som nem luz. Era presença. Ele soube, sem entender como, que aquele era o horário em que sempre fugia de algo importante. O momento em que desligava o celular, mudava de assunto, fingia estar ocupado.
#
#Com as mãos tremendo, ele girou o ponteiro mais uma vez.
#
#Dessa vez, o relógio não mostrou uma lembrança. Mostrou um futuro simples: a oficina aberta de manhã, cheiro de café fresco, alguém entrando e sorrindo como se estivesse finalmente em casa.
#
#O relógio então voltou a funcionar como qualquer outro.
#
#A cidade retomou o barulho. Os semáforos ouviram passos. O vento tirou as meias.
#
#E o rapaz aprendeu que alguns consertos não são feitos com ferramentas — mas com coragem de ficar quando tudo em você quer ir embora.")
	#set_text("alguém.")
	#set_text("oficina")
	#set_text("
	#Os semáforos")
	#set_text("rua.
	#
	#Lá")
	#set_text("Como o planejado")
	#_current_word = "Porque"
	queue_redraw()
	
	_font_size = 50
	
	#_rich_text_label.add_theme_font_override("normal_font", _font)
	#_rich_text_label.add_theme_font_size_override("normal_font_size", _font_size)
	
	# Set the max width to 600
	_paragraph.width = 600
	

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if _is_paused:
			play()
		else:
			stop()

func set_text(text : String) -> void:
	_full_text.define_text(text)
	var regex := RegEx.new()
	regex.compile("\\s+")
	_text = regex.sub(text, " ", true)
	_words = _text.split(" ")
	_set_current_word(0)
	_currently_word_idx = -1

func set_words_per_minute(wpm : float) -> void:
	_words_per_minute = clampf(wpm, MIN_WORDS_PER_MINUTE, MAX_WORDS_PER_MINUTE)
	_currently_words_per_minute = _words_per_minute

func play() -> void:
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

func stop() -> void:
	if not _is_paused:
		@warning_ignore("narrowing_conversion")
		_currently_word_idx = clampi(_currently_word_idx - 1, -1, 9223372036854775807)
		_is_paused = true

func _set_current_word(idx : int) -> void:
	_current_word = _words[idx].strip_edges()
	queue_redraw()

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

	var _text_words : Array[Word] = []

	# for each glyph
	for i in glyphs.size():
		# get the advance (how much the we need to move x)
		var advance = glyphs[i].get("advance", 0)
		
		# get the offset, it may be needed
		#var offset = glyphs[i].get("offset", Vector2.ZERO)
		
		## draw a red rect surrounding the glyph
		#draw_rect(Rect2(Vector2(x + get_viewport_rect().size.x / 2, y), Vector2(advance, ascent + descent)), Color.RED, false)
		_text_words.append(Word.new(Rect2(Vector2(x + size.x / 2, _font_size), Vector2(advance, ascent + descent)), _current_word[i]))
		
		if i == middle_glyph_idx:
			center_letter_position_x = x + size.x / 2 + (advance / 2)
		
		# add the advance to x
		x += advance

	# update y with the ascent and descent of the line
	y += ascent + descent

	var center_position_x : float = size.x / 2

	for i in _text_words.size():
		_text_words[i].rect.position.x -= center_letter_position_x - center_position_x
		_text_words[i].rect.position.y = size.y / 2.0 + _font_size / 4.0
		if i == middle_glyph_idx:
			draw_string(_font, _text_words[i].rect.position, _text_words[i].word, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, Color.RED)
		else:
			draw_string(_font, _text_words[i].rect.position, _text_words[i].word, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size, Color.WHITE)

func _full_text_clicked_on_word(_word : String, idx : int) -> void:
	_set_current_word(idx)
	_currently_word_idx = idx
	stop()

class Word:
	var rect : Rect2
	var word : String
	
	@warning_ignore("shadowed_variable")
	func _init(rect : Rect2, word : String) -> void:
		self.rect = rect
		self.word = word
