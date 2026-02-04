extends Window

@onready var _confirmation_dialog : ConfirmationDialog = $ConfirmationDialog

@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/TagsContainer/MarginContainer/ScrollContainer/TagsFlowContainer
@onready var _erase_button : Button = $MarginContainer/VBoxContainer/EraseButton

const _PRESS_TAG_SCENE : PackedScene = preload("res://books/tag/pressTag/PressTagContainer.tscn")

var _last_press_tag_container : PressTagContainer

func _ready() -> void:
	for tag in Files.get_tags().tags:
		_added_tag(tag)
	
	Files.added_tag.connect(_added_tag)
	Files.removed_tag.connect(_removed_tag)

func _added_tag(tag : TagResource) -> void:
	var press_tag_container : PressTagContainer = _PRESS_TAG_SCENE.instantiate()
	_tags_flow_container.add_child(press_tag_container)
	press_tag_container.set_tag(tag)
	press_tag_container.button_toggled.connect(_press_tag_button_toggled)

func _removed_tag(tag : TagResource) -> void:
	for press_tag_container in _tags_flow_container.get_children():
		if press_tag_container.get_tag() == tag:
			_tags_flow_container.remove_child(press_tag_container)
			return

func _press_tag_button_toggled(press_tag_container : PressTagContainer, toggled_on : bool) -> void:
	if _last_press_tag_container and _last_press_tag_container != press_tag_container:
		_last_press_tag_container.set_pressed(false)
	
	if toggled_on:
		_last_press_tag_container = press_tag_container
		_erase_button.disabled = false
	else:
		_last_press_tag_container = null
		_erase_button.disabled = true

func _on_erase_button_pressed() -> void:
	if not _last_press_tag_container:
		return
	_confirmation_dialog.dialog_text = "Você tem certeza que deseja apagar: \"" + _last_press_tag_container.get_tag().name + "\""
	_confirmation_dialog.popup_centered()

func _on_confirmation_dialog_confirmed() -> void:
	if _last_press_tag_container:
		Files.remove_tag(_last_press_tag_container.get_tag())
		_last_press_tag_container = null
		_erase_button.disabled = true

func _on_close_requested() -> void:
	visible = false

func _on_search_line_edit_text_changed(new_text: String) -> void:
	new_text = new_text.to_lower()
	for child in _tags_flow_container.get_children():
		if child is PressTagContainer:
			child.visible = true if new_text.is_empty() else new_text in child.get_tag().name.to_lower()
