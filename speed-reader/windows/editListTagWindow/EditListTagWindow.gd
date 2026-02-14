extends Window

class_name EditListTagWindow

@onready var _title_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/TitleContainer/TitleRichTextLabel
@onready var _erase_tag_button : Button = $MarginContainer/VBoxContainer/TagButtons/EraseButton
@onready var _new_tag_button : Button = $MarginContainer/VBoxContainer/TagButtons/NewButton
@onready var _search_line_edit : LineEdit = $MarginContainer/VBoxContainer/SearchContainer/SearchLineEdit
@onready var _return_button : Button = $MarginContainer/VBoxContainer/ReturnButton

@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/TagsContainer/MarginContainer/ScrollContainer/TagsFlowContainer

@onready var _new_tag_window : Window = $NewTagWindow
@onready var _erase_tag_window : Window = $EraseTagWindow

const _PRESS_TAG_SCENE : PackedScene = preload("res://books/tag/pressTag/PressTagContainer.tscn")

var _list : ListResource

signal added_tag(tag : TagResource)
signal removed_tag(tag : TagResource)

func _ready() -> void:
	Files.added_tag.connect(_add_tag)
	Files.removed_tag.connect(_remove_tag)
	
	for tag in Files.get_tags().tags:
		_add_tag(tag)
	
	Settings.changed_language.connect(_changed_language)
	_changed_language(Settings.get_language())

func _changed_language(_language : Settings.Languages) -> void:
	title = tr("Edit tags")
	_title_rich_text_label.text = tr("Edit tags")
	_erase_tag_button.text = tr("Erase")
	_new_tag_button.text = tr("New Button")
	_search_line_edit.placeholder_text = tr("Search")
	_return_button.text = tr("Finished")

func _add_tag(tag : TagResource) -> void:
	var press_tag_container : PressTagContainer = _PRESS_TAG_SCENE.instantiate()
	_tags_flow_container.add_child(press_tag_container)
	press_tag_container.set_tag(tag)
	press_tag_container.button_toggled.connect(_press_tag_button_toggled)

func _remove_tag(tag : TagResource) -> void:
	for child in _tags_flow_container.get_children():
		if child is PressTagContainer and child.get_tag().name == tag.name:
			_tags_flow_container.remove_child(child)
			child.queue_free()
			return

func set_list(list : ListResource) -> void:
	_list = list
	
	for child in _tags_flow_container.get_children():
		if not child is PressTagContainer:
			continue
		var found_tag : bool = false
		for tag in _list.tags.tags:
			if child.get_tag().name == tag.name:
				found_tag = true
				break
		child.set_pressed(found_tag)

func get_list() -> ListResource:
	return _list

func _press_tag_button_toggled(press_tag_container : PressTagContainer, toggled_on : bool) -> void:
	if not _list:
		return
	var list_tags_uids : Array[String] = Files.get_list_tags_uids(_list)
	
	if (toggled_on and press_tag_container.get_tag().name in list_tags_uids) or (not toggled_on and not press_tag_container.get_tag().name in list_tags_uids):
		return
	
	if toggled_on:
		_list.tags.tags.append(press_tag_container.get_tag())
		added_tag.emit(press_tag_container.get_tag())
	else:
		for tag in _list.tags.tags:
			if press_tag_container.get_tag().name == tag.name:
				_list.tags.tags.erase(tag)
				removed_tag.emit(tag)
				break

func _on_search_line_edit_text_changed(new_text: String) -> void:
	new_text = new_text.to_lower()
	for child in _tags_flow_container.get_children():
		if child is PressTagContainer:
			child.visible = true if new_text.is_empty() else new_text in child.get_tag().name.to_lower()

func _on_return_button_pressed() -> void:
	queue_free()

func _on_close_requested() -> void:
	queue_free()

func _on_erase_button_pressed() -> void:
	_erase_tag_window.popup_centered()

func _on_new_button_pressed() -> void:
	_new_tag_window.popup_centered()
