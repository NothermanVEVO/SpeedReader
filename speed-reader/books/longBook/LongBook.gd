extends Button

class_name LongBook

var _book : BookResource

@onready var _hbox_container : HBoxContainer = $LongBook

@onready var _cover_image : TextureRect = $LongBook/Cover
@onready var _title_text : RichTextLabel = $LongBook/Info/Title
@onready var _reading_type : OptionButton = $LongBook/Info/Reading
@onready var _stars : SpinBox = $LongBook/Info/Stars
#@onready var _tags : FlowContainer

var _just_loaded_book : bool = false

signal has_toggled(long_book : LongBook, toggled_on : bool)

func _ready() -> void:
	_hbox_container.custom_minimum_size.x = size.x
	custom_minimum_size.y = _hbox_container.custom_minimum_size.y
	resized.connect(_resized)
	_hbox_container.resized.connect(_hbox_resized)
	
	Files.saved_book.connect(_files_saved_book)

func _files_saved_book(book : BookResource) -> void:
	if _book and _book == book:
		load_book(_book)

func _resized() -> void:
	_hbox_container.custom_minimum_size.x = size.x
	custom_minimum_size.y = _hbox_container.custom_minimum_size.y

func _hbox_resized() -> void:
	_hbox_container.custom_minimum_size.x = size.x
	custom_minimum_size.y = _hbox_container.custom_minimum_size.y

func load_book(book : BookResource) -> void:
	_book = book
	
	_title_text.text = book.name
	
	if FileAccess.file_exists(book.current_dir_path + "/cover.png"):
		var image := Image.load_from_file(book.current_dir_path + "/cover.png")
		if image:
			_cover_image.texture = ImageTexture.create_from_image(image)
	if not _cover_image.texture:
		_cover_image.texture = Books.FILE_ICON
	
	_just_loaded_book = true
	
	_reading_type.selected = book.reading_type
	_stars.value = book.stars
	
	_just_loaded_book = false

func get_book() -> BookResource:
	return _book

func _on_reading_item_selected(index: int) -> void:
	_book.reading_type = index
	if not _just_loaded_book:
		Files.save_book(_book)

func _on_stars_value_changed(value: float) -> void:
	_book.stars = int(value)
	if not _just_loaded_book:
		Files.save_book(_book)

func _on_toggled(toggled_on: bool) -> void:
	has_toggled.emit(self, toggled_on)
