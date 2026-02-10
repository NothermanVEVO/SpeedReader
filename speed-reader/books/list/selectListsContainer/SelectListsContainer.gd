extends MarginContainer

class_name SelectListsContainer

const _TOGGLE_LIST_CONTAINER_SCENE : PackedScene = preload("res://books/list/toggleList/ToggleListContainer.tscn")

@onready var _lists_vbox_container : VBoxContainer = $ListsVBoxContainer

@export var _enable_multi_select : bool = false

var _last_selected_toggle_list : ToggleListContainer

signal list_selected(list : ListResource, selected : bool)

func _ready() -> void:
	_resized()
	resized.connect(_resized)
	
	Files.added_custom_list.connect(_add_list)
	
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

func _resized() -> void:
	ToggleListContainer.set_max_size_x(size.x)
