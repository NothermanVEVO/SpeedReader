extends MarginContainer

class_name ManageListContainer

var _list : ListResource

@onready var _name_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/TopContainer/HBoxContainer/NameRichTextLabel
@onready var _background_color_rect : ColorRect = $BackgroundColorRect
@onready var _tags_hbox_container : HBoxContainer = $MarginContainer/VBoxContainer/TagsContainer/ScrollContainer/HBoxContainer
@onready var _books_cover_hbox_container : HBoxContainer = $MarginContainer/VBoxContainer/BottomContainer/ScrollContainer/BooksCovers

const _TAG_CONTAINER_SCENE : PackedScene = preload("res://books/tag/TagContainer.tscn")
const _NEW_LIST_WINDOW_SCENE : PackedScene = preload("res://windows/newListWindow/NewListWindow.tscn")

const _texture_rect_min_size : Vector2 = Vector2(100, 140)
const _texture_rect_expande_mode : TextureRect.ExpandMode = TextureRect.ExpandMode.EXPAND_IGNORE_SIZE

func _ready() -> void:
	Files.saved_custom_list.connect(_files_saved_custom_list)

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
	
	for tag in _list.tags.tags:
		var book_texture_rect := TextureRect.new()
		_books_cover_hbox_container.add_child(book_texture_rect)

func get_list() -> ListResource:
	return _list

func _on_list_button_pressed() -> void:
	pass # Replace with function body.

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
