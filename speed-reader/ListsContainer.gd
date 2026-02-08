extends MarginContainer

func _ready() -> void:
	_resized()
	resized.connect(_resized)

func _resized() -> void:
	ListContainer.set_max_size_x(size.x)
