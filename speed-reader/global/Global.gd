extends Node

func split_text_by_space(text : String) -> PackedStringArray:
	var regex := RegEx.new()
	regex.compile("\\s+")
	text = regex.sub(text, " ", true)
	text = text.strip_edges()
	var s = text.split(" ")
	return s

func is_whitespace(c: String) -> bool:
	return c == " " or c == "\n" or c == "\t" or c == "\r"
