extends Window

class_name NewListWindow

enum Type {NEW_LIST, EDIT_LIST}

var _type : Type = Type.NEW_LIST

var _list : ListResource

@onready var _list_color_rect : ColorRect = $MarginContainer/VBoxContainer/ListResult/ScrollContainer/MarginContainer/ListColorRect
@onready var _list_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/ListResult/ScrollContainer/MarginContainer/MarginContainer/ListRichTextLabel

@onready var _title_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/TitleContainer/TitleRichTextLabel
@onready var _name_line_edit : LineEdit = $MarginContainer/VBoxContainer/NameContainer/HBoxContainer/NameLineEdit
@onready var _background_color_picker : ColorPickerButton = $MarginContainer/VBoxContainer/BackgroundColor/HBoxContainer/BackgroundColorPickerButton
@onready var _foreground_color_picker : ColorPickerButton = $MarginContainer/VBoxContainer/ForegroundColor/HBoxContainer/ForegroundColorPickerButton

@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/TagsResult/MarginContainer/ScrollContainer/TagsFlowContainer

@onready var _erase_button : Button = $MarginContainer/VBoxContainer/HBoxContainer/EraseButton
@onready var _create_button : Button = $MarginContainer/VBoxContainer/HBoxContainer/CreateButton

@onready var _accept_dialog : AcceptDialog = $AcceptDialog

const _TAG_CONTAINER_SCENE : PackedScene = preload("res://books/tag/TagContainer.tscn")
const _EDIT_LIST_TAG_WINDOW_SCENE : PackedScene = preload("res://windows/editListTagWindow/EditListTagWindow.tscn")

func _ready() -> void:
	_reset_list()
	
	set_type(_type)
	
	Files.erase_custom_list.connect(_erase_list)

func set_list(list : ListResource) -> void:
	_list = list
	
	_name_line_edit.text = _list.name
	_list_rich_text_label.text = _list.name
	
	_background_color_picker.color = _list.background_color
	_foreground_color_picker.color = _list.foreground_color
	
	_list_color_rect.color = _list.background_color
	_list_rich_text_label.add_theme_color_override("default_color", _list.foreground_color)
	
	_create_button.disabled = _list.name.is_empty()
	
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

func set_type(type : Type) -> void:
	_type = type
	
	match _type:
		Type.NEW_LIST:
			title = "Nova lista"
			_title_rich_text_label.text = title
			_create_button.text = "Criar"
			_erase_button.visible = false
		Type.EDIT_LIST:
			title = "Editar lista"
			_title_rich_text_label.text = title
			_create_button.text = "Salvar"
			_erase_button.visible = true

func get_list() -> ListResource:
	return _list

func _reset_list() -> void:
	_list = ListResource.new()
	_list.background_color = Color(0.5, 0.5, 0.5, 1.0)
	_list.foreground_color = Color()
	set_list(_list)

func _on_name_line_edit_text_changed(new_text: String) -> void:
	_create_button.disabled = new_text.is_empty()
	
	_list_rich_text_label.text = new_text
	_list.name = new_text

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
	if not _list:
		return
	
	if not Files.can_save_list(_list):
		_accept_dialog.dialog_text = "Erro: Já existe uma lista com o nome: \"" + _list.name + "\""
		_accept_dialog.popup_centered()
		return
	
	match _type:
		Type.NEW_LIST:
			var status := Files.add_custom_list(_list)
			if status == OK:
				_accept_dialog.dialog_text = "A lista \"" + _list.name + "\" foi criada com sucesso!"
				_reset_list()
			else:
				_accept_dialog.dialog_text = "Ocorreu um erro ao criar a lista \"" + _list.name + "\""
		Type.EDIT_LIST:
			var status := Files.save_custom_list(_list)
			if status == OK:
				_accept_dialog.dialog_text = "A lista \"" + _list.name + "\" foi salva com sucesso!"
			else:
				_accept_dialog.dialog_text = "Ocorreu um erro ao salvar a lista \"" + _list.name + "\""
	
	_accept_dialog.popup_centered()

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

func _on_erase_button_pressed() -> void:
	if _list:
		Files.request_to_erase_custom_list(_list)

func _erase_list(list : ListResource) -> void:
	if _list and _list == list:
		queue_free()
