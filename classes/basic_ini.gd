class_name BasicIni

static func parse(data: String) -> Dictionary[String, Dictionary]:
	var result: Dictionary[String, Dictionary]
	var section_name: String
	var section_data: Dictionary

	for line: String in data.split("\n", false):
		# do this otherwise \r can show up
		line = line.strip_escapes().strip_edges()
		if line.is_empty():
			continue
		if line.begins_with(";") or line.begins_with("#"):
			continue # Skip comment.
		if line.begins_with("[") and line.ends_with("]"):
			if not section_data.is_empty():
				result[section_name] = section_data
			section_name = line.trim_prefix("[").trim_suffix("]").to_lower()
			section_data = {}
		else:
			var kv: PackedStringArray = line.split("=", true, 1)
			section_data[kv[0].strip_edges()] = kv[1].strip_edges() if kv.size() > 1 else ""

	if not section_data.is_empty():
		result[section_name] = section_data

	return result


static func make_char_ini(data: Dictionary[String, Dictionary]) -> String:
	var ini_string: String = ""
	if "options" in data:
		ini_string += "[Options]"
		for key: String in data["options"]:
			var value: String = data["options"][key]
			ini_string += "\n%s = %s" % [key, value]
		ini_string += "\n\n"
	if "emotions" in data:
		ini_string += "\n[Emotions]"
		var emote_count: int = data["emotions"].keys().size()
		ini_string += "\nnumber = %s" % emote_count
		for index: int in emote_count:
			var emote_number: String = str(index+1)
			ini_string += "\n%s = %s" % [emote_number, data["emotions"][emote_number]]
	if "soundn" in data:
		ini_string += "\n\n[SoundN]"
		for key: String in data["soundn"]:
			ini_string += "\n%s = %s" % [key, data["soundn"][key]]
	if "soundt" in data:
		ini_string += "\n\n[SoundT]"
		for key: String in data["soundt"]:
			ini_string += "\n%s = %s" % [key, data["soundt"][key]]
	if "soundl" in data:
		ini_string += "\n\n[SoundL]"
		for key: String in data["soundl"]:
			ini_string += "\n%s = %s" % [key, data["soundl"][key]]
	return ini_string
