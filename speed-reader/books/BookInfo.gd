extends MarginContainer

class_name BookInfo

var _book : BookResource

const _TAG_CONTAINER_SCENE : PackedScene = preload("res://books/tag/TagContainer.tscn")
const _EDIT_BOOK_WINDOW_SCENE : PackedScene = preload("res://windows/editBookWindow/EditBookWindow.tscn")

@onready var _cover_image : TextureRect = $BookInfo/Top/Cover
@onready var _title_text : RichTextLabel = $BookInfo/Top/Title
@onready var _reading_options : OptionButton = $BookInfo/Reading
@onready var _stars : SpinBox = $BookInfo/Stars
@onready var _comment_text : TextEdit = $BookInfo/Comments
@onready var _tags_flow_container : FlowContainer = $BookInfo/TagsContainer/ScrollContainer/Tags

@onready var _save_button : Button = $BookInfo/HBoxContainer/Save

func _ready() -> void:
	Files.saved_book.connect(_files_saved_book)

func _files_saved_book(book : BookResource, changed_cover : bool) -> void:
	if _book and _book == book:
		load_book(_book, changed_cover)

func load_book(book : BookResource, load_cover_image : bool = true) -> void:
	_book = book
	
	_save_button.disabled = true
	
	_title_text.text = book.name
	
	if load_cover_image:
		_cover_image.texture = Files.load_cover_image_from_book(_book)
	
	var tags_container_child_count : int = _tags_flow_container.get_child_count()
	var idx : int = 0
	for i in tags_container_child_count:
		var child := _tags_flow_container.get_child(idx)
		if child is TagContainer:
			_tags_flow_container.remove_child(child)
			child.queue_free()
		else:
			idx += 1
	
	for tag in _book.tags.tags:
		var tag_container : TagContainer = _TAG_CONTAINER_SCENE.instantiate()
		_tags_flow_container.add_child(tag_container)
		tag_container.set_tag(tag)
	
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

func _on_edit_button_pressed() -> void:
	if _book:
		var edit_book_window : EditBookWindow = _EDIT_BOOK_WINDOW_SCENE.instantiate()
		add_child(edit_book_window)
		edit_book_window.set_book(_book)
		edit_book_window.popup_centered()
