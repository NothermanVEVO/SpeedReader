extends MarginContainer

class_name BlockBook

var _book : Book

@onready var _cover_image : TextureRect = $ScrollContainer/VBoxContainer/Cover
@onready var _title_text : RichTextLabel = $ScrollContainer/VBoxContainer/Info/Title
@onready var _reading_type : OptionButton = $ScrollContainer/VBoxContainer/Info/Reading
@onready var _stars : SpinBox = $ScrollContainer/VBoxContainer/Info/Stars
#@onready var _tags : FlowContainer

func load_book(book : Book) -> void:
	_book = book
	
	_title_text.text = book.name
	
	if FileAccess.file_exists(book.current_dir_path + "/cover.png"):
		var image := Image.load_from_file(book.current_dir_path + "/cover.png")
		if image:
			_cover_image.texture = ImageTexture.create_from_image(image)
	if not _cover_image.texture:
		_cover_image.texture = Books.FILE_ICON
	
	_reading_type.selected = book.reading_type
	_stars.value = book.stars

func get_book() -> Book:
	return _book

func _on_reading_item_selected(index: int) -> void:
	_book.reading_type = index
	ResourceSaver.save(_book, _book.current_dir_path + "/" + _book.name + ".tres")

func _on_stars_value_changed(value: float) -> void:
	_book.stars = int(value)
	ResourceSaver.save(_book, _book.current_dir_path + "/" + _book.name + ".tres")
