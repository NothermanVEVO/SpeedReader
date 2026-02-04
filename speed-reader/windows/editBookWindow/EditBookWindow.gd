extends Window

class_name EditBookWindow

@onready var _cover_image : TextureRect = $MarginContainer/VBoxContainer/BookContainer/CoverContainer/Cover
@onready var _name_line_edit : LineEdit = $MarginContainer/VBoxContainer/BookContainer/VBoxContainer/HBoxContainer/NameLineEdit
@onready var _save_name_button : Button = $MarginContainer/VBoxContainer/BookContainer/VBoxContainer/HBoxContainer/SaveNameButton
@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/BookContainer/VBoxContainer/TagsContainer/MarginContainer/ScrollContainer/TagsFlowContainer

const _TAG_CONTAINER_SCENE : PackedScene = preload("res://books/tag/TagContainer.tscn")

const _EDIT_BOOK_TAG_WINDOW_SCENE : PackedScene = preload("res://windows/editBookTagWindow/EditBookTagWindow.tscn")

var _book : BookResource

func _ready() -> void:
	Files.saved_book.connect(_files_saved_book)

func _files_saved_book(book : BookResource) -> void:
	set_book(book)

func set_book(book : BookResource) -> void:
	_book = book
	
	_name_line_edit.text = _book.name
	
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

func get_book() -> BookResource:
	return _book

func _on_close_requested() -> void:
	queue_free()

func _on_edit_tag_button_pressed() -> void:
	if _book:
		var edit_book_tag_window : EditBookTagWindow = _EDIT_BOOK_TAG_WINDOW_SCENE.instantiate()
		add_child(edit_book_tag_window)
		edit_book_tag_window.set_book(_book)
		edit_book_tag_window.popup_centered()

func _on_save_name_button_pressed() -> void:
	_book.name = _name_line_edit.text
	print(Files.save_book(_book))
	_save_name_button.disabled = true

func _on_name_line_edit_text_changed(new_text: String) -> void:
	_save_name_button.disabled = new_text == _book.name
