extends Window

@onready var _rich_text_label : RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel
@onready var _link_button : LinkButton = $MarginContainer/VBoxContainer/LinkButton

func _ready() -> void:
	Settings.changed_language.connect(_changed_language)
	_changed_language(Settings.get_language())

func _changed_language(_language : Settings.Languages) -> void:
	_rich_text_label.text = tr("This field accepts BBCode, for example:")
	_link_button.text = tr("Click to find out more")

func _on_close_requested() -> void:
	visible = false
