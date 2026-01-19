extends Node

func split_text_by_space(text : String) -> PackedStringArray:
	var regex := RegEx.new()
	regex.compile("\\s+")
	text = regex.sub(text, " ", true)
	return text.split(" ")
