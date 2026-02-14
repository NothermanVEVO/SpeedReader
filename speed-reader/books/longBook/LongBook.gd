extends Button

class_name LongBook

var _book : BookResource

#@onready var _hbox_container : HBoxContainer = $MarginContainer/LongBook
@onready var _margin_container : MarginContainer = $MarginContainer

@onready var _cover_image : TextureRect = $MarginContainer/LongBook/Cover
@onready var _title_text : RichTextLabel = $MarginContainer/LongBook/Info/Title
@onready var _reading_type : OptionButton = $MarginContainer/LongBook/Info/HBoxContainer/Reading
@onready var _add_to_list_button : Button = $MarginContainer/LongBook/Info/HBoxContainer/AddListButton
@onready var _stars : SpinBox = $MarginContainer/LongBook/Info/Stars
@onready var _tags_flow_container : FlowContainer = $MarginContainer/LongBook/Info/TagsContainer/ScrollContainer/Tags
@onready var _tags_rich_text_label : RichTextLabel = $MarginContainer/LongBook/Info/TagsContainer/ScrollContainer/Tags/TagsText
@onready var _open_button : Button = $MarginContainer/LongBook/Buttons/OpenButton
@onready var _edit_button : Button = $MarginContainer/LongBook/Buttons/Edit
@onready var _delete_button : Button = $MarginContainer/LongBook/Buttons/DeleteButton

const _TAG_CONTAINER_SCENE : PackedScene = preload("res://books/tag/TagContainer.tscn")
const _EDIT_BOOK_WINDOW_SCENE : PackedScene = preload("res://windows/editBookWindow/EditBookWindow.tscn")
const _ADD_BOOK_TO_LIST_SCENE : PackedScene = preload("res://windows/addBookToListWindow/AddBookToListWindow.tscn")

const _SPEED_READER_SCENE : PackedScene = preload("res://speedReader/SpeedReader.tscn")

var _just_loaded_book : bool = false

var _previous_reading_index : int = 0

signal has_toggled(long_book : LongBook, toggled_on : bool)

func _ready() -> void:
	_margin_container.size.x = size.x
	custom_minimum_size.y = _margin_container.size.y
	resized.connect(_resized)
	_margin_container.resized.connect(_hbox_resized)
	
	Files.saved_book.connect(_files_saved_book)
	Files.erase_book.connect(_files_erase_book)
	Settings.changed_language.connect(_changed_language)
	_changed_language(Settings.get_language())

func _changed_language(_language : Settings.Languages) -> void:
	_reading_type.set_item_text(0, "None")
	_reading_type.set_item_text(1, "Reading")
	_reading_type.set_item_text(2, "Plan to read")
	_reading_type.set_item_text(3, "Completed")
	_reading_type.set_item_text(4, "On hold")
	_reading_type.set_item_text(5, "Re-reading")
	_reading_type.set_item_text(6, "Dropped")
	_add_to_list_button.text = "+ " + tr("Add to list")
	_stars.suffix = tr("Stars")
	_tags_rich_text_label.text = tr("Tags") + ": "
	_open_button.text = tr("Open")
	_edit_button.text = tr("Edit")
	_delete_button.text = tr("Erase")

func _files_saved_book(book : BookResource, changed_cover : bool) -> void:
	if _book and _book == book:
		load_book(_book, changed_cover)

func _files_erase_book(book : BookResource) -> void:
	if _book and _book == book:
		queue_free()

func _resized() -> void:
	_margin_container.size.x = size.x
	size.y = _margin_container.size.y

func _hbox_resized() -> void:
	_margin_container.size.x = size.x
	size.y = _margin_container.size.y

func load_book(book : BookResource, load_cover_image : bool = true) -> void:
	_book = book
	
	_title_text.text = book.name
	
	if load_cover_image:
		_cover_image.texture = _book.cover_texture
	
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
		Files.remove_book_from_prepared_list(_book, _previous_reading_index as Files.ReadingTypes)
		Files.add_book_to_prepared_list(_book, index as Files.ReadingTypes)
	_previous_reading_index = index

func _on_stars_value_changed(value: float) -> void:
	_book.stars = int(value)
	if not _just_loaded_book:
		Files.save_book(_book)

func _on_toggled(toggled_on: bool) -> void:
	has_toggled.emit(self, toggled_on)

func _on_edit_pressed() -> void:
	if _book:
		var edit_book_window : EditBookWindow = _EDIT_BOOK_WINDOW_SCENE.instantiate()
		add_child(edit_book_window)
		edit_book_window.set_book(_book)
		edit_book_window.popup_centered()

func _on_delete_button_pressed() -> void:
	Files.request_to_erase_book(_book)

func _on_add_list_button_pressed() -> void:
	if not _book:
		return
	
	var add_book_to_list_window : AddBookToListWindow = _ADD_BOOK_TO_LIST_SCENE.instantiate()
	add_child(add_book_to_list_window)
	add_book_to_list_window.set_book(_book)
	add_book_to_list_window.popup_centered()

func _on_open_button_pressed() -> void:
	if _book:
		Files.current_selected_book = _book
		get_tree().change_scene_to_packed(_SPEED_READER_SCENE)
