extends MarginContainer

class_name SelectListsContainer

const _TOGGLE_LIST_CONTAINER_SCENE : PackedScene = preload("res://books/list/toggleList/ToggleListContainer.tscn")

enum ListType{PREPARED, CUSTOM}

@onready var _lists_vbox_container : VBoxContainer = $ListsVBoxContainer

@export var _enable_multi_select : bool = false

var _last_selected_toggle_list : ToggleListContainer

var _current_list_type : ListType

var _max_size_x : float = 200

signal list_selected(list : ListResource, selected : bool)

func _ready() -> void:
	_resized()
	resized.connect(_resized)
	
	Files.added_custom_list.connect(_add_list)

func set_list_type(list_type : ListType) -> void:
	_current_list_type = list_type
	
	match _current_list_type:
		ListType.PREPARED:
			var lists := Files.get_prepared_lists()
			for list in lists.lists:
				_add_list(list)
		ListType.CUSTOM:
			var lists := Files.get_custom_lists()
			for list in lists.lists:
				_add_list(list)

func _add_list(list : ListResource) -> void:
	var toggled_list_container : ToggleListContainer = _TOGGLE_LIST_CONTAINER_SCENE.instantiate()
	_lists_vbox_container.add_child(toggled_list_container)
	toggled_list_container.set_list(list)
	toggled_list_container.toggled.connect(_list_toggled)

func set_list_pressed(list : ListResource, pressed : bool) -> void:
	for child in _lists_vbox_container.get_children():
		if child is ToggleListContainer and child.get_list().name == list.name:
			child.set_pressed(pressed)

func _list_toggled(toggle_list_container : ToggleListContainer, toggled_on : bool) -> void:
	if not _enable_multi_select and _last_selected_toggle_list and _last_selected_toggle_list.get_list() != toggle_list_container:
		_last_selected_toggle_list.set_pressed(false)
		_last_selected_toggle_list = null
	
	if toggled_on:
		_last_selected_toggle_list = toggle_list_container
	
	list_selected.emit(toggle_list_container.get_list(), toggled_on)

func set_lists_visible_by_name(text : String) -> void:
	text = text.to_lower()
	var _toggle_list : Array[Node] = _lists_vbox_container.get_children()
	for i in _toggle_list.size():
		if _toggle_list[i] is ToggleListContainer:
			_toggle_list[i].visible = true if text.is_empty() else text in _toggle_list[i].get_list().name.to_lower()

func _resized() -> void:
	for child in _lists_vbox_container.get_children():
		if child is ToggleListContainer:
			child.set_max_size_x(_max_size_x)

func set_max_size_x(max_size_x : float) -> void:
	_max_size_x = max_size_x
	_resized()
