extends MarginContainer

@onready var _language_title : RichTextLabel = $VBoxContainer/LanguageTitle
@onready var _language_option_button : OptionButton = $VBoxContainer/LanguageOptionButton

func _ready() -> void:
	Settings.changed_language.connect(_set_text_by_language)
	_set_text_by_language(Settings.get_language())

func _set_text_by_language(_language : Settings.Languages) -> void:
	_language_title.text = tr("Language") + ":"
	_language_option_button.selected = Settings.get_language()

func _on_language_option_button_item_selected(index: int) -> void:
	match _language_option_button.get_item_text(index):
		"English":
			Settings.set_language(Settings.Languages.ENGLISH)
		"Espanõl":
			Settings.set_language(Settings.Languages.SPANISH)
		"Português":
			Settings.set_language(Settings.Languages.PORTUGUESE)
