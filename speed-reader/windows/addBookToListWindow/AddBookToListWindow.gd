extends Window

class_name AddBookToListWindow

const _NEW_LIST_WINDOW_SCENE : PackedScene = preload("res://windows/newListWindow/NewListWindow.tscn")

@onready var _select_lists_container : SelectListsContainer = $MarginContainer/VBoxContainer/ScrollContainer/SelectListsContainer

var _book : BookResource

func _ready() -> void:
	_select_lists_container.list_selected.connect(_list_selected)

func set_book(book : BookResource) -> void:
	_book = book
	
	if not _book:
		return
	
	var selected_lists : Array[ListResource] = Files.get_custom_lists_from_book(_book)
	for list in selected_lists:
		_select_lists_container.set_list_pressed(list, true)

func get_book() -> BookResource:
	return _book

func _list_selected(list : ListResource, selected : bool) -> void:
	if not _book or (selected and _book.get_ID() in list.books_ids) or (not selected and not _book.get_ID() in list.books_ids):
		return
	
	if selected:
		list.books_ids.append(_book.get_ID())
	else:
		list.books_ids.erase(_book.get_ID())
	
	Files.save_custom_list(list)

func _on_close_requested() -> void:
	queue_free()

func _on_new_list_button_pressed() -> void:
	var new_list_window : NewListWindow = _NEW_LIST_WINDOW_SCENE.instantiate()
	add_child(new_list_window)
	new_list_window.popup_centered()

func _on_ready_button_pressed() -> void:
	queue_free()
