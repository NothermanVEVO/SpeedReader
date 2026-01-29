extends Resource

class_name Book

@export var _ID : String
@export var name : String
@export var reading_type : int
@export var stars : int
@export var comment : String
@export var tags : Array[int]
@export var creation_time : float

var current_dir_path : String = ""

@warning_ignore("shadowed_variable")
func _init(name : String = "", reading_type : int = 0, stars : int = 0, comment : String = "", tags : Array[int] = []) -> void:
	_ID = Global.get_UUID()
	self.name = name
	self.reading_type = reading_type
	self.stars = stars
	self.comment = comment
	self.tags = tags

func get_ID() -> String:
	return _ID
