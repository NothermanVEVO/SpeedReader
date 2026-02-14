extends Window

class_name EditBookWindow

@onready var _title_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/TitleContainer/TitleRichTextLabel
@onready var _cover_image : TextureRect = $MarginContainer/VBoxContainer/BookContainer/CoverContainer/Cover
@onready var _name_line_edit : LineEdit = $MarginContainer/VBoxContainer/BookContainer/VBoxContainer/HBoxContainer/NameLineEdit
@onready var _save_name_button : Button = $MarginContainer/VBoxContainer/BookContainer/VBoxContainer/HBoxContainer/SaveNameButton
@onready var _tags_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/BookContainer/VBoxContainer/TagsContainer/MarginContainer/ScrollContainer/TagsFlowContainer/TagsRichTextLabel
@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/BookContainer/VBoxContainer/TagsContainer/MarginContainer/ScrollContainer/TagsFlowContainer
@onready var _edit_tags_button : Button = $MarginContainer/VBoxContainer/BookContainer/VBoxContainer/EditTagButton
@onready var _erase_button : Button = $MarginContainer/VBoxContainer/ButtonsContainer/DeleteButton
@onready var _return_button : Button = $MarginContainer/VBoxContainer/ButtonsContainer/ReturnButton

@onready var _file_dialog : FileDialog = $FileDialog
@onready var _accept_dialog : AcceptDialog = $AcceptDialog

const _TAG_CONTAINER_SCENE : PackedScene = preload("res://books/tag/TagContainer.tscn")

const _EDIT_BOOK_TAG_WINDOW_SCENE : PackedScene = preload("res://windows/editBookTagWindow/EditBookTagWindow.tscn")

var _book : BookResource

func _ready() -> void:
	Files.saved_book.connect(_files_saved_book)
	Files.erase_book.connect(_files_erase_book)
	Settings.changed_language.connect(_changed_language)
	_changed_language(Settings.get_language())

func _changed_language(_language : Settings.Languages) -> void:
	title = tr("Edit book")
	_title_rich_text_label.text = tr("Edit book")
	_name_line_edit.placeholder_text = tr("Book's name") + "..."
	_save_name_button.text = tr("Save")
	_tags_rich_text_label.text = tr("Tags") + ":"
	_edit_tags_button.text = tr("Edit tags")
	_erase_button.text = tr("Erase")
	_return_button.text = tr("Finished")

func _files_erase_book(book : BookResource) -> void:
	if _book and _book == book:
		queue_free()

func _files_saved_book(book : BookResource, changed_cover : bool) -> void:
	if _book and _book == book:
		set_book(_book, changed_cover)

func set_book(book : BookResource, load_cover_image : bool = true) -> void:
	_book = book
	
	_name_line_edit.text = _book.name
	
	if load_cover_image:
		_cover_image.texture = _book.cover_texture
	
	var tags_container_child_count : int = _tags_flow_container.get_child_count()
	var idx : int = 0
	for i in tags_container_child_count:
		var child := _tags_flow_container.get_child(idx)
		if child is TagContainer:
			_tags_flow_container.remove_child(child)
			child.queue_free()
		else:
			idx += 1
	
	for tag in _book.tags.tags:
		var tag_container : TagContainer = _TAG_CONTAINER_SCENE.instantiate()
		_tags_flow_container.add_child(tag_container)
		tag_container.set_tag(tag)

func get_book() -> BookResource:
	return _book

func _on_close_requested() -> void:
	queue_free()

func _on_edit_tag_button_pressed() -> void:
	if _book:
		var edit_book_tag_window : EditBookTagWindow = _EDIT_BOOK_TAG_WINDOW_SCENE.instantiate()
		add_child(edit_book_tag_window)
		edit_book_tag_window.set_book(_book)
		edit_book_tag_window.popup_centered()

func _on_save_name_button_pressed() -> void:
	_book.name = _name_line_edit.text
	Files.save_book(_book)
	_save_name_button.disabled = true

func _on_name_line_edit_text_changed(new_text: String) -> void:
	_save_name_button.disabled = new_text == _book.name

func _on_files_dropped(files: PackedStringArray) -> void:
	var path : String = files[0]
	if Files.can_load_image(path):
		var cover_texture := Files.load_image(path)
		var status := Files.save_book_cover(_book, cover_texture)
		if status == OK:
			_cover_image.texture = cover_texture
		else:
			_accept_dialog.dialog_text = "Erro: Desconhecido!"
			_accept_dialog.popup_centered()
	else:
		_accept_dialog.dialog_text = "Erro: Tipo de arquivo não aceito! Só são aceito nos formatos: " + str(Files.VALID_IMAGE_EXTENSION)
		_accept_dialog.popup_centered()

func _on_cover_button_pressed() -> void:
	_file_dialog.popup_centered()

func _on_file_dialog_file_selected(path: String) -> void:
	_on_files_dropped(PackedStringArray([path]))

func _on_return_button_pressed() -> void:
	queue_free()

func _on_delete_button_pressed() -> void:
	Files.request_to_erase_book(_book)
