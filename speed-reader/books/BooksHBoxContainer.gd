extends HBoxContainer

@onready var _lists_rich_text_label : RichTextLabel = $LeftBar/MarginContainer/VBoxContainer/Lists/ListsRichTextLabel
@onready var _manage_list_button : Button = $LeftBar/MarginContainer/VBoxContainer/ManageListButton
@onready var _settings_button : Button = $MiddleBar/VBoxContainer/TopBar/HBoxContainer/Settings
@onready var _type_rich_text_label : RichTextLabel = $MiddleBar/VBoxContainer/TopBar/HBoxContainer/Type/TypeRichTextLabel
@onready var _type_option_button : OptionButton = $MiddleBar/VBoxContainer/TopBar/HBoxContainer/Type/ShowTypeOption
@onready var _sort_rich_text_label : RichTextLabel = $MiddleBar/VBoxContainer/TopBar/HBoxContainer/Sort/SortRichTextLabel
@onready var _sort_option_button : OptionButton = $MiddleBar/VBoxContainer/TopBar/HBoxContainer/Sort/SortOption
@onready var _filter_button : Button = $MiddleBar/VBoxContainer/TopBar/HBoxContainer/Filter
@onready var _new_file_button : Button = $"MiddleBar/VBoxContainer/TopBar/HBoxContainer/New File"
@onready var _search_line_edit : LineEdit = $MiddleBar/VBoxContainer/SearchBar/SearchLineEdit

func _ready() -> void:
	Settings.changed_language.connect(_changed_language)
	_changed_language(Settings.get_language())

func _changed_language(_language : Settings.Languages) -> void:
	_lists_rich_text_label.text = tr("Lists")
	_manage_list_button.text = tr("Manage lists")
	_settings_button.text = tr("Settings")
	_type_rich_text_label.text = tr("Type") + ":"
	_type_option_button.set_item_text(0, tr("Long"))
	_type_option_button.set_item_text(1, tr("Block"))
	_sort_rich_text_label.text = tr("Sort") + ":"
	_sort_option_button.set_item_text(0, tr("Used recently"))
	_sort_option_button.set_item_text(1, tr("Used oldest"))
	_sort_option_button.set_item_text(2, tr("Added recently"))
	_sort_option_button.set_item_text(3, tr("Added oldest"))
	_sort_option_button.set_item_text(4, tr("Alphabetical") + "(" + tr("Ascending") + ")")
	_sort_option_button.set_item_text(5, tr("Alphabetical") + "(" + tr("Descending") + ")")
	_filter_button.text = tr("Filter")
	_new_file_button.text = tr("New file")
	_search_line_edit.placeholder_text = tr("Search")
