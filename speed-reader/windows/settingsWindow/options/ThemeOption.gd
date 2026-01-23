extends MarginContainer

@onready var theme_option_button : OptionButton = $VBoxContainer/ThemeOptionButton

func _on_theme_option_button_item_selected(index: int) -> void:
	var id := theme_option_button.get_item_id(index)
	Global.set_theme(id)
