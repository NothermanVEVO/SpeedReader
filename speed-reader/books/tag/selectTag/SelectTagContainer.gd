extends MarginContainer

class_name SelectTagContainer

const UNSELECTED_ICON : CompressedTexture2D = preload("res://assets/icons/unselected_v2.png")
const SELECTED_INCLUDE_ICON : CompressedTexture2D = preload("res://assets/icons/selected_include.png")
const SELECTED_EXCLUDE_ICON : CompressedTexture2D = preload("res://assets/icons/selected_exclude.png")

@onready var _icon_rect : TextureRect = $HBoxContainer/IconRect
@onready var _tag_container : TagContainer = $HBoxContainer/Tag

signal changed_select_type(select_tag_container : SelectTagContainer)

func set_select_type(type : TagResource.SelectType) -> void:
	_tag_container.get_tag().select_type = type
	changed_select_type.emit(self)
	if is_inside_tree():
		match _tag_container.get_tag().select_type:
			TagResource.SelectType.UNSELECTED:
				_icon_rect.texture = UNSELECTED_ICON
				_icon_rect.visible = false
			TagResource.SelectType.SELECTED_INCLUDE:
				_icon_rect.texture = SELECTED_INCLUDE_ICON
				_icon_rect.visible = true
			TagResource.SelectType.SELECTED_EXCLUDE:
				_icon_rect.texture = SELECTED_EXCLUDE_ICON
				_icon_rect.visible = true

func get_select_type() -> TagResource.SelectType:
	return _tag_container.get_tag().select_type

func set_tag(tag : TagResource) -> void:
	_tag_container.set_tag(tag)
	set_select_type(_tag_container.get_tag().select_type)

func get_tag() -> TagResource:
	return _tag_container.get_tag()

func _on_button_pressed() -> void:
	if _tag_container.get_tag().select_type == TagResource.SelectType.UNSELECTED:
		set_select_type(TagResource.SelectType.SELECTED_INCLUDE)
	elif _tag_container.get_tag().select_type == TagResource.SelectType.SELECTED_INCLUDE:
		set_select_type(TagResource.SelectType.SELECTED_EXCLUDE)
	else:
		set_select_type(TagResource.SelectType.UNSELECTED)
