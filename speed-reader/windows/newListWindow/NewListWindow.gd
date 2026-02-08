extends Window

var _list : ListResource

@onready var _list_color_rect : ColorRect = $MarginContainer/VBoxContainer/ListResult/ScrollContainer/MarginContainer/ListColorRect
@onready var _list_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/ListResult/ScrollContainer/MarginContainer/MarginContainer/ListRichTextLabel

@onready var _name_line_edit : LineEdit = $MarginContainer/VBoxContainer/NameContainer/HBoxContainer/NameLineEdit
@onready var _background_color_picker : ColorPickerButton = $MarginContainer/VBoxContainer/BackgroundColor/HBoxContainer/BackgroundColorPickerButton
@onready var _foreground_color_picker : ColorPickerButton = $MarginContainer/VBoxContainer/ForegroundColor/HBoxContainer/ForegroundColorPickerButton

@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/TagsResult/MarginContainer/ScrollContainer/TagsFlowContainer

@onready var _create_button : Button = $MarginContainer/VBoxContainer/CreateButton

const _TAG_CONTAINER_SCENE : PackedScene = preload("res://books/tag/TagContainer.tscn")
const _EDIT_LIST_TAG_WINDOW_SCENE : PackedScene = preload("res://windows/editListTagWindow/EditListTagWindow.tscn")

func _ready() -> void:
	_list = ListResource.new()
	_list.background_color = Color(0.5, 0.5, 0.5, 1.0)
	_list.foreground_color = Color()
	
	set_list(_list)

func set_list(list : ListResource) -> void:
	_list = list
	
	_list_rich_text_label.text = _list.name
	
	_background_color_picker.color = _list.background_color
	_foreground_color_picker.color = _list.foreground_color
	
	_list_color_rect.color = _list.background_color
	_list_rich_text_label.add_theme_color_override("default_color", _list.foreground_color)
	
	var tags_container_child_count : int = _tags_flow_container.get_child_count()
	var idx : int = 0
	for i in tags_container_child_count:
		var child := _tags_flow_container.get_child(idx)
		if child is TagContainer:
			_tags_flow_container.remove_child(child)
			child.queue_free()
		else:
			idx += 1
	
	for tag in _list.tags.tags:
		_added_tag(tag)

func get_list() -> ListResource:
	return _list

func _on_name_line_edit_text_changed(new_text: String) -> void:
	_create_button.disabled = new_text.is_empty()
	
	_list_rich_text_label.text = new_text

func _on_background_color_picker_button_color_changed(color: Color) -> void:
	_list_color_rect.color = color
	_list.background_color = color

func _on_foreground_color_picker_button_color_changed(color: Color) -> void:
	_list_rich_text_label.add_theme_color_override("default_color", color)
	_list.foreground_color = color

func _on_edit_tag_button_pressed() -> void:
	var _edit_list_tag_window : EditListTagWindow = _EDIT_LIST_TAG_WINDOW_SCENE.instantiate()
	_edit_list_tag_window.added_tag.connect(_added_tag)
	_edit_list_tag_window.removed_tag.connect(_removed_tag)
	add_child(_edit_list_tag_window)
	_edit_list_tag_window.set_list(_list)
	_edit_list_tag_window.popup_centered()

func _on_create_button_pressed() -> void:
	pass # Replace with function body.

func _on_close_requested() -> void:
	queue_free()

func _added_tag(tag : TagResource) -> void:
	var tag_container : TagContainer = _TAG_CONTAINER_SCENE.instantiate()
	_tags_flow_container.add_child(tag_container)
	tag_container.set_tag(tag)

func _removed_tag(tag_to_remove : TagResource) -> void:
	for child in _tags_flow_container.get_children():
		if child is TagContainer and child.get_tag().resource_scene_unique_id == tag_to_remove.resource_scene_unique_id:
			child.queue_free()
