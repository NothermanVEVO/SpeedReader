extends MarginContainer

class_name AllListsSelectContainer

@onready var _toggle_all_list_container : ToggleListContainer = $ScrollContainer/VBoxContainer/AllList
@onready var _select_prepared_lists_container : SelectListsContainer = $ScrollContainer/VBoxContainer/SelectPreparedListsContainer
@onready var _select_custom_lists_container : SelectListsContainer = $ScrollContainer/VBoxContainer/SelectCustomListsContainer

var _last_list_pressed : ListResource

signal list_selected(list : ListResource)

func _ready() -> void:
	_resized()
	resized.connect(_resized)
	
	_toggle_all_list_container.set_list(Files.get_all_list())
	_select_prepared_lists_container.set_list_type(SelectListsContainer.ListType.PREPARED)
	_select_custom_lists_container.set_list_type(SelectListsContainer.ListType.CUSTOM)

func set_selected_list(list : ListResource) -> void:
	if list == _toggle_all_list_container.get_list():
		_toggle_all_list_container.set_pressed(true)
	elif Files.prepared_lists_has_list(list):
		_select_prepared_lists_container.set_list_pressed(list, true)
	elif Files.custom_lists_has_list(list):
		_select_custom_lists_container.set_list_pressed(list, true)

func _resized() -> void:
	size.x = custom_minimum_size.x
	_select_prepared_lists_container.set_max_size_x(custom_minimum_size.x)
	_select_custom_lists_container.set_max_size_x(custom_minimum_size.x)

func _on_all_list_toggled(toggle_list_container: ToggleListContainer, toggled_on: bool) -> void:
	if not toggled_on:
		_all_check_for_no_pressed_list.call_deferred()
	
	if toggled_on:
		if _last_list_pressed and _last_list_pressed != toggle_list_container.get_list():
			if Files.prepared_lists_has_list(_last_list_pressed):
				_select_prepared_lists_container.set_list_pressed(_last_list_pressed, false)
			elif Files.custom_lists_has_list(_last_list_pressed):
				_select_custom_lists_container.set_list_pressed(_last_list_pressed, false)
		if _last_list_pressed != toggle_list_container.get_list():
			_last_list_pressed = toggle_list_container.get_list()
			list_selected.emit(_last_list_pressed)

func _all_check_for_no_pressed_list() -> void:
	if _last_list_pressed == _toggle_all_list_container.get_list():
		_toggle_all_list_container.set_pressed.call_deferred(true)

func _on_select_prepared_lists_container_list_selected(list: ListResource, selected: bool) -> void:
	if not selected:
		_prepared_check_for_no_pressed_list.call_deferred(list)
	
	if selected:
		if _last_list_pressed and _last_list_pressed != list:
			if _last_list_pressed.name == Files.get_all_list().name:
				_toggle_all_list_container.set_pressed(false)
			elif Files.custom_lists_has_list(_last_list_pressed):
				_select_custom_lists_container.set_list_pressed(_last_list_pressed, false)
		if _last_list_pressed != list:
			_last_list_pressed = list
			list_selected.emit(_last_list_pressed)

func _prepared_check_for_no_pressed_list(list : ListResource) -> void:
	if _last_list_pressed == list:
		_select_prepared_lists_container.set_list_pressed(list, true)

func _on_select_custom_lists_container_list_selected(list: ListResource, selected: bool) -> void:
	if not selected:
		_custom_check_for_no_pressed_list.call_deferred(list)
	
	if selected:
		if _last_list_pressed and _last_list_pressed != list:
			if _last_list_pressed.name == Files.get_all_list().name:
				_toggle_all_list_container.set_pressed(false)
			elif Files.prepared_lists_has_list(_last_list_pressed):
				_select_prepared_lists_container.set_list_pressed(_last_list_pressed, false)
		if _last_list_pressed != list:
			_last_list_pressed = list
			list_selected.emit(_last_list_pressed)

func _custom_check_for_no_pressed_list(list : ListResource) -> void:
	if _last_list_pressed == list:
		_select_custom_lists_container.set_list_pressed(list, true)
