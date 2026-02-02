extends Window

@onready var _new_tag_window : Window = $NewTagWindow
@onready var _erase_tag_window : Window = $EraseTagWindow

@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/TagsContainer/MarginContainer/ScrollContainer/TagsFlowContainer

const _SELECT_TAG_SCENE : PackedScene = preload("res://books/tag/selectTag/SelectTagContainer.tscn")

func _ready() -> void:
	for tag in Files.get_tags().tags:
		var select_tag_container : SelectTagContainer = _SELECT_TAG_SCENE.instantiate()
		_tags_flow_container.add_child(select_tag_container)
		select_tag_container.set_tag(tag)
	
	Files.added_tag.connect(_added_tag)
	Files.removed_tag.connect(_removed_tag)

func _added_tag(tag : TagResource) -> void:
	var select_tag_container : SelectTagContainer = _SELECT_TAG_SCENE.instantiate()
	_tags_flow_container.add_child(select_tag_container)
	select_tag_container.set_tag(tag)

func _removed_tag(tag : TagResource) -> void:
	for select_tag_container in _tags_flow_container.get_children():
		if select_tag_container.get_tag() == tag:
			_tags_flow_container.remove_child(select_tag_container)
			return

func _on_new_button_pressed() -> void:
	_new_tag_window.popup_centered()

func _on_close_requested() -> void:
	visible = false

func _on_erase_button_pressed() -> void:
	_erase_tag_window.popup_centered()
