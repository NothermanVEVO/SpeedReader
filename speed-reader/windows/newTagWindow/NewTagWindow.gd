extends Window

@onready var _tag_container : TagContainer = $MarginContainer/VBoxContainer/Tag/TagContainer

@onready var _name_line_edit : LineEdit = $MarginContainer/VBoxContainer/NameContainer/HBoxContainer/NameLineEdit
@onready var _background_color_picker_button : ColorPickerButton = $MarginContainer/VBoxContainer/BackgroundColor/HBoxContainer/BackgroundColorPickerButton
@onready var _foreground_color_picker_button : ColorPickerButton = $MarginContainer/VBoxContainer/ForegroundColor/HBoxContainer/ForegroundColorPickerButton

@onready var _create_button : Button = $MarginContainer/VBoxContainer/CreateButton

@onready var _accept_dialog : AcceptDialog = $AcceptDialog

func _ready() -> void:
	_background_color_picker_button.color = _tag_container.get_tag().background_color

func _on_name_line_edit_text_changed(new_text: String) -> void:
	_create_button.disabled = new_text.is_empty()
	
	_tag_container.set_text(new_text)

func _on_background_color_picker_button_color_changed(color: Color) -> void:
	_tag_container.set_background(color)

func _on_foreground_color_picker_button_color_changed(color: Color) -> void:
	_tag_container.set_foreground(color)

func _on_create_button_pressed() -> void:
	var tag := _tag_container.get_tag()
	if not Files.can_add_tag(tag):
		_accept_dialog.dialog_text = "Erro: Já existe uma tag com o nome \"" + tag.name + "\""
	else:
		var status := Files.add_tag(tag)
		if status == OK:
			_accept_dialog.dialog_text = "Sucesso: Tag \"" + tag.name + "\" foi adicionado com sucesso!"
			_tag_container.set_tag(TagResource.new("", Color(0.5, 0.5, 0.5, 1.0)))
			_name_line_edit.text = ""
			_background_color_picker_button.color = Color(0.5, 0.5, 0.5, 1.0)
			_foreground_color_picker_button.color = Color()
		else:
			_accept_dialog.dialog_text = "Erro: Desconhecido!"
	_accept_dialog.popup_centered()

func _on_close_requested() -> void:
	visible = false
