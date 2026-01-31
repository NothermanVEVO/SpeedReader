extends MarginContainer

class_name BookInfo

var _book : BookResource

@onready var _cover_image : TextureRect = $BookInfo/Top/Cover
@onready var _title_text : RichTextLabel = $BookInfo/Top/Title
@onready var _reading_options : OptionButton = $BookInfo/Reading
@onready var _stars : SpinBox = $BookInfo/Stars
@onready var _comment_text : TextEdit = $BookInfo/Comments

@onready var _save_button : Button = $BookInfo/HBoxContainer/Save

func _ready() -> void:
	Files.saved_book.connect(_files_saved_book)

func _files_saved_book(book : BookResource) -> void:
	if _book and _book == book:
		load_book(_book)

func load_book(book : BookResource) -> void:
	_book = book
	
	_save_button.disabled = true
	
	_title_text.text = book.name
	
	if FileAccess.file_exists(book.current_dir_path + "/cover.png"):
		var image := Image.load_from_file(book.current_dir_path + "/cover.png")
		if image:
			_cover_image.texture = ImageTexture.create_from_image(image)
	if not _cover_image.texture:
		_cover_image.texture = Books.FILE_ICON
	
	_reading_options.selected = book.reading_type
	_stars.value = book.stars
	_comment_text.text = book.comment

func get_book() -> BookResource:
	return _book

func _on_reading_item_selected(index: int) -> void:
	_book.reading_type = index
	Files.save_book(_book)

func _on_stars_value_changed(value: float) -> void:
	_book.stars = int(value)
	Files.save_book(_book)

func _on_comments_text_changed() -> void:
	_save_button.disabled = false

func _on_save_pressed() -> void:
	_book.comment = _comment_text.text
	Files.save_book(_book)
	_save_button.disabled = true
