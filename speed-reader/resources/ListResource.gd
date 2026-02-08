extends Resource

class_name ListResource

@export var books_ids : PackedStringArray
@export var name : String ## UNIQUE
@export var background_color : Color
@export var foreground_color : Color
@export var creation_time : float

@export var tags : TagsResource

@warning_ignore("shadowed_variable")
func _init(books_ids : PackedStringArray = PackedStringArray(), name : String = "", background_color : Color = Color(), foreground_color : Color = Color(), tags : TagsResource = TagsResource.new()) -> void:
	self.books_ids = books_ids
	self.name = name
	self.background_color = background_color
	self.foreground_color = foreground_color
	self.tags = tags

func get_tags_uids() -> PackedStringArray:
	var uids := PackedStringArray()
	
	for tag in tags.tags:
		uids.append(tag.name)
	
	return uids
