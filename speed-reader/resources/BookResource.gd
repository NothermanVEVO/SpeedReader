extends Resource

class_name BookResource

@export var _ID : String
@export var name : String
@export var reading_type : int
@export var stars : int
@export var comment : String
@export var tags : TagsResource
@export var creation_time : float

@export var sizes_by_pages : Array[SizePagesResource]
@export var last_word_byte_pos : int

var current_dir_path : String = ""
var cover_texture : Texture2D

@warning_ignore("shadowed_variable")
func _init(name : String = "", reading_type : int = 0, stars : int = 0, comment : String = "", tags : TagsResource = TagsResource.new(), sizes_by_pages : Array[SizePagesResource] = [], last_word_byte_pos : int = 0) -> void:
	_ID = Global.get_UUID()
	self.name = name
	self.reading_type = reading_type
	self.stars = stars
	self.comment = comment
	self.tags = tags
	self.sizes_by_pages = sizes_by_pages
	self.last_word_byte_pos = last_word_byte_pos

func get_tags_uids() -> PackedStringArray:
	var uids := PackedStringArray()
	
	for tag in tags.tags:
		uids.append(tag.name)
	
	return uids

func get_ID() -> String:
	return _ID
