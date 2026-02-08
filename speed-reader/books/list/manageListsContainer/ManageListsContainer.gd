extends MarginContainer

const _NEW_LIST_WINDOW_SCENE : PackedScene = preload("res://windows/newListWindow/NewListWindow.tscn")
const _MANAGE_LIST_CONTAINER_SCENE : PackedScene = preload("res://books/list/manageListContainer/ManageListContainer.tscn")

@onready var _search_line_edit : LineEdit = $VBoxContainer/SearchContainer/SearchLineEdit
@onready var _lists_vbox_container : VBoxContainer = $VBoxContainer/ScrollContainer/ListsVBoxContainer

@onready var _tags_window : TagsWindow = $TagsWindow

var _lists : ListsResource

var _current_sort_type : Files.SortType

var _filtered_books_visibility : Array[bool] = []

var _last_include_tags : Array[TagResource] = []
var _last_exclude_tags : Array[TagResource] = []
var _last_include_mode : TagsWindow.OptionMode
var _last_exclude_mode : TagsWindow.OptionMode

func _ready() -> void:
	_lists = Files.get_custom_lists()
	
	for list in _lists.lists:
		_add_custom_list(list)
	
	Files.added_custom_list.connect(_add_custom_list)
	Files.erase_custom_list.connect(_remove_custom_list)
	
	Files.sorted_custom_lists.connect(_files_sorted_custom_lists)
	_tags_window.confirmation_pressed.connect(_tags_window_confirmation_pressed)

func _tags_window_confirmation_pressed(include_tags : Array[TagResource], exclude_tags : Array[TagResource], include_mode : TagsWindow.OptionMode, exclude_mode : TagsWindow.OptionMode) -> void:
	_last_include_tags = include_tags
	_last_exclude_tags = exclude_tags
	_last_include_mode = include_mode
	_last_exclude_mode = exclude_mode
	
	_filtered_books_visibility.clear()
	
	for child in _lists_vbox_container.get_children():
		child.visible = true
		_filtered_books_visibility.append(true)
	
	set_invisible_lists(include_tags, include_mode, true)
	set_invisible_lists(exclude_tags, exclude_mode, false)
	
	_on_search_line_edit_text_changed(_search_line_edit.text)

func set_invisible_lists(tags : Array[TagResource], option_mode : TagsWindow.OptionMode, is_include : bool) -> void:
	if tags.is_empty():
		return
	
	if option_mode == TagsWindow.OptionMode.AND:
		for i in _lists.lists.size():
			var tags_uids := _lists.lists[i].get_tags_uids()
			var has_tag := true
			for tag in tags:
				has_tag = tag.name in tags_uids
				if not has_tag:
					break
			if (is_include and not has_tag) or (not is_include and has_tag):
				_lists_vbox_container.get_child(i).visible = false
				_filtered_books_visibility[i] = false
	else: ## OR
		for i in _lists.lists.size():
			var tags_uids := _lists.lists[i].get_tags_uids()
			var has_tag := false
			for tag in tags:
				has_tag = tag.name in tags_uids
				if has_tag:
					break
			if (is_include and not has_tag) or (not is_include and has_tag):
				_lists_vbox_container.get_child(i).visible = false
				_filtered_books_visibility[i] = false

func _files_sorted_custom_lists(sort_type : Files.SortType) -> void:
	_current_sort_type = sort_type
	
	for i in _lists.lists.size():
		for child in _lists_vbox_container.get_children():
			if child is ManageListContainer and child.get_list() == _lists.lists[i]:
				_lists_vbox_container.move_child.call_deferred(child, i)

func _add_custom_list(list : ListResource) -> void:
	var manage_list_container : ManageListContainer = _MANAGE_LIST_CONTAINER_SCENE.instantiate()
	_lists_vbox_container.add_child(manage_list_container)
	manage_list_container.set_list(list)
	_on_sort_option_item_selected(_current_sort_type)

func _remove_custom_list(list : ListResource) -> void:
	for child in _lists_vbox_container.get_children():
		if child is ManageListContainer and child.get_list() == list:
			_lists_vbox_container.remove_child(child)
			child.queue_free()
			break
	_tags_window_confirmation_pressed(_last_include_tags, _last_exclude_tags, _last_include_mode, _last_exclude_mode)

func _on_sort_option_item_selected(index: int) -> void:
	_current_sort_type = index as Files.SortType
	
	Files.set_custom_list_sort_type(_current_sort_type)
	
	_tags_window_confirmation_pressed.call_deferred(_last_include_tags, _last_exclude_tags, _last_include_mode, _last_exclude_mode)

func _on_filter_button_pressed() -> void:
	_tags_window.popup_centered()

func _on_search_line_edit_text_changed(new_text: String) -> void:
	new_text = new_text.to_lower()
	var manages_lists_containers : Array[Node] = _lists_vbox_container.get_children()
	for i in manages_lists_containers.size():
		if manages_lists_containers[i] is ManageListContainer:
			var search_visible : bool = true if new_text.is_empty() else new_text in manages_lists_containers[i].get_list().name.to_lower()
			manages_lists_containers[i].visible = search_visible and _filtered_books_visibility[i]

func _on_new_list_button_pressed() -> void:
	var new_list_window : NewListWindow = _NEW_LIST_WINDOW_SCENE.instantiate()
	add_child(new_list_window)
	new_list_window.set_type(NewListWindow.Type.NEW_LIST)
	new_list_window.popup_centered()
