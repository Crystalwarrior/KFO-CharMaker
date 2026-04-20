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
			section_name = line.trim_prefix("[").trim_suffix("]")
			section_data = {}
		else:
			var kv: PackedStringArray = line.split("=", true, 1)
			section_data[kv[0].strip_edges()] = kv[1].strip_edges() if kv.size() > 1 else ""

	if not section_data.is_empty():
		result[section_name] = section_data

	return result
