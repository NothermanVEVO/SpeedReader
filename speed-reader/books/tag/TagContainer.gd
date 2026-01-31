extends MarginContainer

class_name TagContainer

const ROUND_RECT_RADIUS : int = 6

var _text : String
var _background_color : Color
var _foreground_color : Color

@onready var _rich_text_label : RichTextLabel = $MarginContainer/RichTextLabel

var _tag : TagResource = TagResource.new()

func _ready() -> void:
	set_text(_tag.name)
	set_background(_tag.background_color)
	set_foreground(_tag.foreground_color)
	resized.connect(_resized)

func set_tag(tag : TagResource) -> void:
	_tag = tag

func get_tag() -> TagResource:
	return _tag

func _resized() -> void:
	queue_redraw()

func _draw() -> void:
	var rect := get_rect()
	rect.position = Vector2.ZERO ## BECAUSE THE CONTAINER SIZING FLAG IS CENTER
	draw_round_rect(rect, _background_color, ROUND_RECT_RADIUS)

func set_text(text : String) -> void:
	_text = text
	_tag.name = text
	for tag in Files._tags.tags:
		print(tag.name)
	if is_inside_tree():
		_rich_text_label.clear()
		_rich_text_label.append_text(text)

func set_background(color : Color) -> void:
	_background_color = color
	_tag.background_color = color
	queue_redraw()

func set_foreground(color : Color) -> void:
	_foreground_color = color
	_tag.foreground_color = color
	if is_inside_tree():
		_rich_text_label.add_theme_color_override("default_color", _foreground_color)

func draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	radius = min(radius, rect.size.x / 2.0, rect.size.y / 2.0)

	var x = rect.position.x
	var y = rect.position.y
	var w = rect.size.x
	var h = rect.size.y
	var r = radius

	# Center
	draw_rect(Rect2(x + r, y + r, w - 2*r, h - 2*r), color, true, -1, true)

	# Laterais
	draw_rect(Rect2(x + r, y, w - 2*r, r), color, true, -1, true)               # top
	draw_rect(Rect2(x + r, y + h - r, w - 2*r, r), color, true, -1, true)       # bottom
	draw_rect(Rect2(x, y + r, r, h - 2*r), color, true, -1, true)               # left
	draw_rect(Rect2(x + w - r, y + r, r, h - 2*r), color, true, -1, true)       # right

	# Round borders (circles)
	draw_circle(Vector2(x + r, y + r), r, color, true, -1, true)                       # top left
	draw_circle(Vector2(x + w - r, y + r), r, color, true, -1, true)                   # top right
	draw_circle(Vector2(x + r, y + h - r), r, color, true, -1, true)                   # bottom left
	draw_circle(Vector2(x + w - r, y + h - r), r, color, true, -1, true)               # bottom right
