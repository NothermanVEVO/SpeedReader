extends Window

class_name EditListBooksWindow

const _TOGGLE_BOOK_CONTAINER_SCENE : PackedScene = preload("res://books/toggleBook/ToggleBookContainer.tscn")

@onready var _background_color_rect : ColorRect = $MarginContainer/VBoxContainer/ListTitleContainer/BackgroundColorRect
@onready var _list_name_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/ListTitleContainer/ListNameRichTextLabel
@onready var _books_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/BookMenuContainer/HBoxContainer/BooksRichTextLabel
@onready var _sort_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/BookMenuContainer/HBoxContainer/Sort/SortRichTextLabel
@onready var _filter_button : Button = $MarginContainer/VBoxContainer/BookMenuContainer/HBoxContainer/FilterButton
@onready var _search_line_edit : LineEdit = $MarginContainer/VBoxContainer/SearchContainer/SearchLineEdit
@onready var _books_flow_container : FlowContainer = $MarginContainer/VBoxContainer/BooksFlowContainer
@onready var _ready_button : Button = $MarginContainer/VBoxContainer/ReadyButton

@onready var _tags_window : TagsWindow = $TagsWindow

var _current_sort_type : Files.SortType

var _filtered_books_visibility : Array[bool] = []

var _list : ListResource

func _ready() -> void:
	set_list(Files.get_custom_lists().lists[0])
	
	Files.sorted_books.connect(_files_sorted_books)
	_tags_window.confirmation_pressed.connect(_tags_window_confirmation_pressed)
	Settings.changed_language.connect(_changed_language)
	_changed_language(Settings.get_language())

func _changed_language(_language : Settings.Languages) -> void:
	_books_rich_text_label.text = tr("Books")
	_sort_rich_text_label.text = tr("Sort") + ":"
	_filter_button.text = tr("Filter")
	_search_line_edit.placeholder_text = tr("Search")
	_ready_button.text = tr("Finished")

func _files_sorted_books(sort_type : Files.SortType) -> void:
	_current_sort_type = sort_type
	
	var books := Files.get_books()
	
	for i in books.size():
		for child in _books_flow_container.get_children():
			if child is ToggleBookContainer and child.get_book() == books[i]:
				_books_flow_container.move_child.call_deferred(child, i)

func _tags_window_confirmation_pressed(include_tags : Array[TagResource], exclude_tags : Array[TagResource], include_mode : TagsWindow.OptionMode, exclude_mode : TagsWindow.OptionMode) -> void:
	_filtered_books_visibility.clear()
	
	for child in _books_flow_container.get_children():
		child.visible = true
		_filtered_books_visibility.append(true)
	
	set_invisible_books(include_tags, include_mode, true)
	set_invisible_books(exclude_tags, exclude_mode, false)
	
	_on_search_line_edit_text_changed(_search_line_edit.text)

func set_invisible_books(tags : Array[TagResource], option_mode : TagsWindow.OptionMode, is_include : bool) -> void:
	if tags.is_empty():
		return
	
	var books := Files.get_books()
	
	if option_mode == TagsWindow.OptionMode.AND:
		for i in books.size():
			var tags_uids := books[i].get_tags_uids()
			var has_tag := true
			for tag in tags:
				has_tag = tag.name in tags_uids
				if not has_tag:
					break
			if (is_include and not has_tag) or (not is_include and has_tag):
				_books_flow_container.get_child(i).visible = false
				_filtered_books_visibility[i] = false
	else: ## OR
		for i in books.size():
			var tags_uids := books[i].get_tags_uids()
			var has_tag := false
			for tag in tags:
				has_tag = tag.name in tags_uids
				if has_tag:
					break
			if (is_include and not has_tag) or (not is_include and has_tag):
				_books_flow_container.get_child(i).visible = false
				_filtered_books_visibility[i] = false

func set_list(list : ListResource) -> void:
	_list = list
	
	if not _list:
		return
	
	_background_color_rect.color = _list.background_color
	_list_name_rich_text_label.text = _list.name
	_list_name_rich_text_label.add_theme_color_override("default_color", _list.foreground_color)
	
	var books_flow_container_child_count : int = _books_flow_container.get_child_count()
	var idx : int = 0
	for i in books_flow_container_child_count:
		var child := _books_flow_container.get_child(idx)
		if child is ToggleBookContainer:
			_books_flow_container.remove_child(child)
			child.queue_free()
		else:
			idx += 1
	
	var books := Files.get_books()
	
	_filtered_books_visibility.clear()
	
	for book in books:
		var toggle_book_container : ToggleBookContainer = _TOGGLE_BOOK_CONTAINER_SCENE.instantiate()
		_books_flow_container.add_child(toggle_book_container)
		toggle_book_container.set_book(book)
		_filtered_books_visibility.append(true)
		toggle_book_container.toggled.connect(_book_toggled)
		if book.get_ID() in _list.books_ids:
			toggle_book_container.set_pressed(true)

func get_list() -> ListResource:
	return _list

func _book_toggled(book : BookResource, toggled_on : bool) -> void:
	if (toggled_on and book.get_ID() in _list.books_ids) or (not toggled_on and not book.get_ID() in _list.books_ids):
		return
	
	if toggled_on:
		_list.books_ids.append(book.get_ID())
	else: ## TOGGLED OFF
		_list.books_ids.erase(book.get_ID())
	
	Files.save_custom_list(_list)

func _on_close_requested() -> void:
	queue_free()

func _on_ready_button_pressed() -> void:
	queue_free()

func _on_sort_option_item_selected(index: int) -> void:
	_current_sort_type = index as Files.SortType
	
	Files.set_book_sort_type(_current_sort_type)

func _on_filter_button_pressed() -> void:
	_tags_window.popup_centered()

func _on_search_line_edit_text_changed(new_text: String) -> void:
	new_text = new_text.to_lower()
	var toggle_books : Array[Node] = _books_flow_container.get_children()
	for i in toggle_books.size():
		if toggle_books[i] is ToggleBookContainer:
			var search_visible : bool = true if new_text.is_empty() else new_text in toggle_books[i].get_book().name.to_lower()
			toggle_books[i].visible = search_visible and _filtered_books_visibility[i]
