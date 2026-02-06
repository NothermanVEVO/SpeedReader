extends Window

class_name TagsWindow

@onready var _new_tag_window : Window = $NewTagWindow
@onready var _erase_tag_window : Window = $EraseTagWindow

@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/TagsContainer/MarginContainer/ScrollContainer/TagsFlowContainer

@onready var _include_option_button : OptionButton = $MarginContainer/VBoxContainer/OptionsContainer/VBoxContainer/HBoxContainer/InclusionContainer/HBoxContainer/IncludeOptionButton
@onready var _exclude_option_button : OptionButton = $MarginContainer/VBoxContainer/OptionsContainer/VBoxContainer/HBoxContainer/ExclusionContainer/HBoxContainer/ExcludeOptionButton

const _SELECT_TAG_SCENE : PackedScene = preload("res://books/tag/selectTag/SelectTagContainer.tscn")

var _include_tags : Array[TagResource] = []
var _exclude_tags : Array[TagResource] = []

enum OptionMode{AND = 0, OR = 1}

signal confirmation_pressed(include_tags : Array[TagResource], exclude_tags : Array[TagResource], include_mode : OptionMode, exclude_mode : OptionMode)

func _ready() -> void:
	for tag in Files.get_tags().tags:
		_added_tag(tag)
	
	Files.added_tag.connect(_added_tag)
	Files.removed_tag.connect(_removed_tag)

func _select_tag_changed_select_type(select_tag_container : SelectTagContainer) -> void:
	var tag : TagResource = select_tag_container.get_tag()
	match select_tag_container.get_select_type():
		TagResource.SelectType.UNSELECTED:
			_exclude_tags.erase(tag)
		TagResource.SelectType.SELECTED_INCLUDE:
			_include_tags.append(tag)
		TagResource.SelectType.SELECTED_EXCLUDE:
			_include_tags.erase(tag)
			_exclude_tags.append(tag)

func _added_tag(tag : TagResource) -> void:
	var select_tag_container : SelectTagContainer = _SELECT_TAG_SCENE.instantiate()
	_tags_flow_container.add_child(select_tag_container)
	select_tag_container.set_tag(tag)
	select_tag_container.changed_select_type.connect(_select_tag_changed_select_type)

func _removed_tag(tag : TagResource) -> void:
	for select_tag_container in _tags_flow_container.get_children():
		if select_tag_container.get_tag() == tag:
			_tags_flow_container.remove_child(select_tag_container)
			select_tag_container.changed_select_type.disconnect(_select_tag_changed_select_type)
			return

func _on_new_button_pressed() -> void:
	_new_tag_window.popup_centered()

func _on_close_requested() -> void:
	visible = false

func _on_erase_button_pressed() -> void:
	_erase_tag_window.popup_centered()

func _on_search_line_edit_text_changed(new_text: String) -> void:
	new_text = new_text.to_lower()
	for child in _tags_flow_container.get_children():
		if child is SelectTagContainer:
			## BUG IF TAG HAS BBCODE, THE SEARCH WILL COUNT
			child.visible = true if new_text.is_empty() else new_text in child.get_tag().name.to_lower()

func _on_confirm_button_pressed() -> void:
	confirmation_pressed.emit(_include_tags, _exclude_tags, _include_option_button.selected as OptionMode, _exclude_option_button.selected as OptionMode)
	visible = false

func _on_reset_button_pressed() -> void:
	for select_tag_container in _tags_flow_container.get_children():
		if select_tag_container is SelectTagContainer:
			select_tag_container.set_select_type(TagResource.SelectType.UNSELECTED)
	_include_tags.clear()
	_exclude_tags.clear()
