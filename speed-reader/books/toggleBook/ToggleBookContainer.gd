extends MarginContainer

class_name ToggleBookContainer

@onready var _button : Button = $Button
@onready var _cover_texture_rect : TextureRect = $MarginContainer/VBoxContainer/CoverTextureRect
@onready var _name_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/NameRichTextLabel
@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/TagsScrollContainer/TagsFlowContainer
@onready var _check_box : CheckBox = $MarginContainer/VBoxContainer/CheckBox

const _TAG_CONTAINER_SCENE : PackedScene = preload("res://books/tag/TagContainer.tscn")

var _book : BookResource

signal toggled(book : BookResource, toggled_on : bool)

func set_book(book : BookResource) -> void:
	_book = book
	
	if not _book:
		return
	
	_cover_texture_rect.texture = _book.cover_texture
	_name_rich_text_label.text = _book.name
	
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

func set_pressed(pressed : bool) -> void:
	_button.button_pressed = pressed

func _on_button_toggled(toggled_on: bool) -> void:
	_check_box.button_pressed = toggled_on
	if _book:
		toggled.emit(_book, toggled_on)
