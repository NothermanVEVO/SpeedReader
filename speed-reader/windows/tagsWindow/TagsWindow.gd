extends Window

class_name TagsWindow

@onready var _new_tag_window : Window = $NewTagWindow
@onready var _erase_tag_window : Window = $EraseTagWindow

@onready var _tags_flow_container : FlowContainer = $MarginContainer/VBoxContainer/TagsContainer/MarginContainer/ScrollContainer/TagsFlowContainer

@onready var _title_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/TitleContainer/TitleRichTextLabel
@onready var _erase_tag_button : Button = $MarginContainer/VBoxContainer/HBoxContainer/EraseButton
@onready var _add_tag_button : Button = $MarginContainer/VBoxContainer/HBoxContainer/NewButton
@onready var _search_line_edit : LineEdit = $MarginContainer/VBoxContainer/SearchContainer/HBoxContainer/SearchLineEdit
@onready var _options_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/OptionsContainer/VBoxContainer/OptionsRichTextLabel
@onready var _include_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/OptionsContainer/VBoxContainer/HBoxContainer/InclusionContainer/HBoxContainer/IncludeRichTextLabel
@onready var _include_option_button : OptionButton = $MarginContainer/VBoxContainer/OptionsContainer/VBoxContainer/HBoxContainer/InclusionContainer/HBoxContainer/IncludeOptionButton
@onready var _exclude_rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/OptionsContainer/VBoxContainer/HBoxContainer/ExclusionContainer/HBoxContainer/ExcludeRichTextLabel
@onready var _exclude_option_button : OptionButton = $MarginContainer/VBoxContainer/OptionsContainer/VBoxContainer/HBoxContainer/ExclusionContainer/HBoxContainer/ExcludeOptionButton
@onready var _reset_choices_button : Button = $MarginContainer/VBoxContainer/OptionsContainer/VBoxContainer/HBoxContainer/ResetButton
@onready var _confirm_button : Button = $MarginContainer/VBoxContainer/OptionsContainer/VBoxContainer/HBoxContainer/ConfirmButton

const _SELECT_TAG_SCENE : PackedScene = preload("res://books/tag/selectTag/SelectTagContainer.tscn")

var _include_tags : Array[TagResource] = []
var _exclude_tags : Array[TagResource] = []

enum OptionMode{AND = 0, OR = 1}

signal confirmation_pressed(include_tags : Array[TagResource], exclude_tags : Array[TagResource], include_mode : OptionMode, exclude_mode : OptionMode)

static var _last_include_mode : OptionMode = OptionMode.AND
static var _last_exclude_mode : OptionMode = OptionMode.OR

func _ready() -> void:
	for tag in Files.get_tags().tags:
		_added_tag(tag)
	
	_include_option_button.select(_last_include_mode)
	_exclude_option_button.select(_last_exclude_mode)
	
	Files.added_tag.connect(_added_tag)
	Files.removed_tag.connect(_removed_tag)
	Settings.changed_language.connect(_changed_language)
	_changed_language(Settings.get_language())

func _changed_language(_language : Settings.Languages) -> void:
	title = tr("Filter tags")
	_title_rich_text_label.text = tr("Filter tags")
	_erase_tag_button.text = tr("Erase tag")
	_add_tag_button.text = tr("Add tag")
	_search_line_edit.placeholder_text = tr("Search")
	_options_rich_text_label.text = tr("Options") + ":"
	_include_rich_text_label.text = tr("Include Mode") + ":"
	_include_option_button.set_item_text(0, tr("And"))
	_include_option_button.set_item_text(1, tr("Or"))
	_exclude_rich_text_label.text = tr("Exclude Mode") + ":"
	_exclude_option_button.set_item_text(0, tr("And"))
	_exclude_option_button.set_item_text(1, tr("Or"))
	_reset_choices_button.text = tr("Reset choices")
	_confirm_button.text = tr("Confirm")

func _select_tag_changed_select_type(select_tag_container : SelectTagContainer) -> void:
	var tag : TagResource = select_tag_container.get_tag()
	match select_tag_container.get_select_type():
		TagResource.SelectType.UNSELECTED:
			_exclude_tags.erase(tag)
		TagResource.SelectType.SELECTED_INCLUDE:
			_include_tags.append(tag)
		TagResource.SelectType.SELECTED_EXCLUDE:
			_include_tags.erase(tag)
			_exclude_tags.append(tag)

func _added_tag(tag : TagResource) -> void:
	var select_tag_container : SelectTagContainer = _SELECT_TAG_SCENE.instantiate()
	_tags_flow_container.add_child(select_tag_container)
	select_tag_container.set_tag(tag)
	_select_tag_changed_select_type(select_tag_container)
	select_tag_container.changed_select_type.connect(_select_tag_changed_select_type)

func _removed_tag(tag : TagResource) -> void:
	for select_tag_container in _tags_flow_container.get_children():
		if select_tag_container.get_tag() == tag:
			_tags_flow_container.remove_child(select_tag_container)
			select_tag_container.changed_select_type.disconnect(_select_tag_changed_select_type)
			return

func _on_new_button_pressed() -> void:
	_new_tag_window.popup_centered()

func _on_close_requested() -> void:
	visible = false

func _on_erase_button_pressed() -> void:
	_erase_tag_window.popup_centered()

func _on_search_line_edit_text_changed(new_text: String) -> void:
	new_text = new_text.to_lower()
	for child in _tags_flow_container.get_children():
		if child is SelectTagContainer:
			## BUG IF TAG HAS BBCODE, THE SEARCH WILL COUNT
			child.visible = true if new_text.is_empty() else new_text in child.get_tag().name.to_lower()

func _on_confirm_button_pressed() -> void:
	_last_include_mode = _include_option_button.selected as OptionMode
	_last_exclude_mode = _exclude_option_button.selected as OptionMode
	confirmation_pressed.emit(_include_tags, _exclude_tags, _last_include_mode, _last_exclude_mode)
	visible = false

func _on_reset_button_pressed() -> void:
	for select_tag_container in _tags_flow_container.get_children():
		if select_tag_container is SelectTagContainer:
			select_tag_container.set_select_type(TagResource.SelectType.UNSELECTED)
	_include_option_button.select(OptionMode.AND)
	_exclude_option_button.select(OptionMode.OR)
	_include_tags.clear()
	_exclude_tags.clear()
