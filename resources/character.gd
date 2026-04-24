extends Resource

## Contains all the data necessary for the character to function
class_name Character

## The Absolute Path of the char.ini currently tied to this character reference
@export var ini_path: String

## Specifies which folder to look for character assets, i.e.
## this should be named the same as the character folder.
## Starts from the characters/ folder.
@export var char_name: String = ""
## What to show in the Character's Nameplate. This is local-only,
## meaning only you will see the changes unless you share the files.
@export var showname: String = ""
## If false, use a blank showname. Note:
## this follows the same rules as Showname.
@export var needs_showname: bool = true
## defaults to: wit
## Modifies where in the courtroom the character initially appears.
## This is commonly called your pos, or position.
@export var side: String = "wit"
## defaults to: male
## The sound that plays for each letter. Blip sound effects can be located in
## sounds/blips/[blip] or sounds/general/sfx-[blip]
@export var blips: String = "male"
## Custom chatbox/interjections to use. Input should be
## a directory in misc/ containing the chatbox you want to use.
## Note that users can disable these in their settings.
@export var chat: String = ""
## specifies misc folder to search for overlay effects, similar to Chat option
@export var effects: String = ""
## Specifies custom realization sound to be played.
## Must be located in base/sounds/general.
@export var realization: String = ""
## The category to be used for the character list.
@export var category: String = ""
## Resize modes are used to determine how content is meant to be scaled up/down.[br]
## pixel: pixelated look (nearest neighbour) is retained when scaled.[br]
## smooth: A smoother look (bilinear) is applied when scaled.[br]
@export var scaling: String = ""
## The Emotes stored on this character.
@export var emotes: Array[Emote] = []


## Load the data obtained from BasicIni.parse(file.get_as_text())
func load_data(data: Dictionary[String, Dictionary]) -> void:
	if "emotions" in data:
		var emotions: Dictionary = data["emotions"]
		for key: String in emotions:
			if key.to_lower() == "number":
				continue
			var value: String = emotions[key]
			var emote_args: PackedStringArray = value.split("#", true)
			if emote_args.size() < 4:
				push_warning("Misformatted char.ini: ", ini_path, ", ", key, " = ", value)
				continue
			# desk mod is not always included
			emote_args.resize(5)
			var emote: Emote = Emote.new(
				emote_args[0],
				emote_args[1],
				emote_args[2],
				emote_args[3],
				emote_args[4],
			)
			# This index is counted from 1 instead of 0 unfortunately
			var ini_idx: int = emotes.size() + 1
			if "soundn" in data:
				if str(ini_idx) in data["soundn"]:
					emote.sound_name = data["soundn"][str(ini_idx)]
			if "soundt" in data:
				if str(ini_idx) in data["soundt"]:
					emote.sound_time = data["soundt"][str(ini_idx)]
			if "soundl" in data:
				if str(ini_idx) in data["soundl"]:
					var emote_soundl: bool = false
					if data["soundl"][str(ini_idx)] == "1":
						emote_soundl = true
					emote.sound_loop = emote_soundl
			emotes.append(emote)
	if "options" in data:
		var options: Dictionary = data["options"]
		if "name" in options:
			char_name = options["name"]
		if "showname" in options:
			showname = options["showname"]
		if "needs_showname" in options:
			needs_showname = not options["needs_showname"].begins_with("false")
		if "side" in options:
			side = options["side"]
		if "gender" in options:
			blips = options["gender"]
		if "blips" in options:
			blips = options["blips"]
		if "chat" in options:
			chat = options["chat"]
		if "effects" in options:
			effects = options["effects"]
		if "realization" in options:
			realization = options["realization"]
		if "category" in options:
			category = options["category"]
		if "scaling" in options:
			scaling = options["scaling"]


## Save the data into BasicIni style format
func save_data() -> Dictionary:
	var data: Dictionary[String, Dictionary]
	data["emotions"] = { }
	data["options"] = { }
	for i: int in emotes.size():
		var number_string: String = str(i + 1)
		var emote: Emote = emotes[i]
		data["emotions"][number_string] = "#".join(
			[emote.display_name, emote.pre, emote.idle, emote.emote_mod, emote.desk_mod],
		)
		if not emote.sound_name.is_empty() and emote.sound_name not in ["-1", "0", "1"]:
			if not "soundn" in data:
				data["soundn"] = { }
			data["soundn"][number_string] = emote.sound_name
		if emote.sound_time > 0:
			if not "soundt" in data:
				data["soundt"] = { }
			data["soundt"][number_string] = emote.sound_time
		if emote.sound_loop == true:
			if not "soundl" in data:
				data["soundl"] = { }
			data["soundl"][number_string] = emote.sound_loop
	data["options"]["name"] = char_name
	data["options"]["showname"] = showname
	if needs_showname == true:
		data["options"]["needs_showname"] = str(needs_showname)
	if not side.is_empty():
		data["options"]["side"] = side
	if not blips.is_empty():
		data["options"]["blips"] = blips
	if not chat.is_empty():
		data["options"]["chat"] = chat
	if not effects.is_empty():
		data["options"]["effects"] = effects
	if not realization.is_empty():
		data["options"]["realization"] = realization
	if not category.is_empty():
		data["options"]["category"] = category
	if not scaling.is_empty():
		data["options"]["scaling"] = scaling
	return data


## Get the Character Folder absolute path.
func get_folder() -> String:
	return ini_path.get_base_dir()
