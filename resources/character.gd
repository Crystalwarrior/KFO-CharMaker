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
			var emote: Emote = Emote.new(emote_args[0], emote_args[1], emote_args[2], emote_args[3], emote_args[4])
			emotes.append(emote)
			
			# set soundN for emote
			if "soundn" in data:
				if str(emotes.size()) in data["soundn"]:
					emotes[emotes.size()-1].sound_name = data["soundn"][str(emotes.size())]

			# set soundT for emote
			if "soundt" in data:
				if str(emotes.size()) in data["soundt"]:
					emotes[emotes.size()-1].sound_time = data["soundt"][str(emotes.size())]

			# set soundL for emote
			if "soundl" in data:
				if str(emotes.size()) in data["soundl"]:
					var emote_soundl
					if data["soundl"][str(emotes.size())] == "1":
						emote_soundl = true
					else:
						emote_soundl = false
					emotes[emotes.size()-1].sound_loop = emote_soundl
					
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
	var data = {}
	# TODO: save the data dictionary properly
	#data["name"] = char_name
	#data["showname"] = showname
	#data["needs_showname"] = str(needs_showname)
	#data["side"] = side
	#data["gender"] = blips
	#data["blips"] = blips
	#data["chat"] = chat
	#data["effects"] = effects
	#data["realization"] = realization
	#data["category"] = category
	#data["scaling"] = scaling
	return data

## Get the Character Folder absolute path.
func get_folder() -> String:
	return ini_path.get_base_dir()
