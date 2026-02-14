extends MarginContainer

class_name ManageListContainer

var _list : ListResource

@onready var _edit_button : Button = $MarginContainer/VBoxContainer/TopContainer/HBoxContainer/HBoxContainer/EditButton
@onready var _erase_button : Button = $MarginContainer/VBoxContainer/TopContainer/HBoxContainer/HBoxContainer/EraseButton
@onready var _tags_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/TagsContainer/ScrollContainer/HBoxContainer/TagsRichTextLabel

@onready var _name_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/TopContainer/HBoxContainer/NameRichTextLabel
@onready var _background_color_rect : ColorRect = $BackgroundColorRect
@onready var _tags_hbox_container : HBoxContainer = $MarginContainer/VBoxContainer/TagsContainer/ScrollContainer/HBoxContainer
@onready var _books_cover_hbox_container : HBoxContainer = $MarginContainer/VBoxContainer/BottomContainer/ScrollContainer/BooksCovers

const _TAG_CONTAINER_SCENE : PackedScene = preload("res://books/tag/TagContainer.tscn")
const _NEW_LIST_WINDOW_SCENE : PackedScene = preload("res://windows/newListWindow/NewListWindow.tscn")

const _BOOKS_CONTAINER_SCENE : PackedScene = preload("res://books/Books.tscn")

const _EDIT_LIST_BOOKS_WINDOW_SCENE : PackedScene = preload("res://windows/editListBooksWindow/EditListBooksWindow.tscn")

const _TEXTURE_RECT_MIN_SIZE : Vector2 = Vector2(100, 140)
const _TEXTURE_RECT_EXPANDE_MODE : TextureRect.ExpandMode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE

func _ready() -> void:
	Files.saved_custom_list.connect(_files_saved_custom_list)
	Settings.changed_language.connect(_changed_language)
	_changed_language(Settings.get_language())

func _changed_language(_language : Settings.Languages) -> void:
	_edit_button.text = tr("Edit")
	_erase_button.text = tr("Erase")
	_tags_rich_text_label.text = tr("Tags") + ": "

func _files_saved_custom_list(list : ListResource) -> void:
	if _list and _list == list:
		set_list(list)

func set_list(list : ListResource) -> void:
	_list = list
	
	_background_color_rect.color = _list.background_color
	
	_name_rich_text_label.text = _list.name
	_name_rich_text_label.add_theme_color_override("default_color", _list.foreground_color)
	
	var tags_container_child_count : int = _tags_hbox_container.get_child_count()
	var idx : int = 0
	for i in tags_container_child_count:
		var child := _tags_hbox_container.get_child(idx)
		if child is TagContainer:
			_tags_hbox_container.remove_child(child)
			child.queue_free()
		else:
			idx += 1
	
	for tag in _list.tags.tags:
		var tag_container : TagContainer = _TAG_CONTAINER_SCENE.instantiate()
		_tags_hbox_container.add_child(tag_container)
		tag_container.set_tag(tag)
	
	var books_covers_container_child_count : int = _books_cover_hbox_container.get_child_count()
	idx = 0
	for i in books_covers_container_child_count:
		var child := _books_cover_hbox_container.get_child(idx)
		if child is TextureRect:
			_books_cover_hbox_container.remove_child(child)
			child.queue_free()
		else:
			idx += 1
	
	for book_id in _list.books_ids:
		var book_texture_rect := TextureRect.new()
		book_texture_rect.custom_minimum_size = _TEXTURE_RECT_MIN_SIZE
		book_texture_rect.expand_mode = _TEXTURE_RECT_EXPANDE_MODE
		book_texture_rect.texture = Files.get_book(book_id).cover_texture
		_books_cover_hbox_container.add_child(book_texture_rect)

func get_list() -> ListResource:
	return _list

func _on_list_button_pressed() -> void:
	if _list:
		Books.set_selected_list_value(_list)
		get_tree().change_scene_to_packed(_BOOKS_CONTAINER_SCENE)

func _on_edit_button_pressed() -> void:
	if not _list:
		return
	var new_list_window : NewListWindow = _NEW_LIST_WINDOW_SCENE.instantiate()
	add_child(new_list_window)
	new_list_window.set_type(NewListWindow.Type.EDIT_LIST)
	new_list_window.set_list(_list)
	new_list_window.popup_centered()

func _on_erase_button_pressed() -> void:
	if not _list:
		return
	Files.request_to_erase_custom_list(_list)

func _on_add_book_button_pressed() -> void:
	if not _list:
		return
	var edit_list_books_window : EditListBooksWindow = _EDIT_LIST_BOOKS_WINDOW_SCENE.instantiate()
	add_child(edit_list_books_window)
	edit_list_books_window.set_list(_list)
	edit_list_books_window.popup_centered()
