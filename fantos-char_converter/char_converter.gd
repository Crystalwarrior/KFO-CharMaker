extends Control

@onready var file_dialog: FileDialog = %FileDialog
@onready var char_icon_file_dialog: FileDialog = %CharIconFileDialog
@onready var convert_button: Button = %ConvertButton
@onready var emote_list: ItemList = %EmoteList
@onready var char_container: AspectRatioContainer = %CharContainer
@onready var preview_texture_rect: TextureRect = %PreviewTextureRect
@onready var showname_edit: LineEdit = %ShownameEdit
@onready var character_icon: TextureRect = %"Character Icon"
@onready var char_icon_load_button: Button = $"Left Menu/MenuList/CharacterFold/Character/CharIconLoadButton"


@export var preview_height: float = 1.0

var position_offset_normal: Vector2 = Vector2(0.0, 0.0)

const VALID_SECTIONS: PackedStringArray = [
	# General character options
	"options",
	# Shout properties
	"shouts",
	# Preanim duration, no longer used
	"time",
	# Numbered emotes of the character
	"emotions",
	# Emote's SFX Name
	"soundn",
	# Emote's SFX Delay
	"soundt",
	# Emote's blip sound override
	"soundb",
	# Emote's SFX looping status
	"soundl",
	# Emote's assocaited video
	"videos",
	# Numbered emote's associated frame SFX data
	"#_FrameSFX",
	# Numbered emote's associated frame screenshake data
	"#_FrameScreenshake",
	# Numbered emote's associated frame realization data
	"#_FrameRealization",
]

var current_emotes: Array[Emote] = []
var current_char_folder

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	convert_button.pressed.connect(_on_convert_button_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	char_icon_load_button.pressed.connect(_on_charIconLoad_button_pressed)
	char_icon_file_dialog.file_selected.connect(load_char_icon_from_filepath)
	emote_list.item_selected.connect(_on_emote_selected)

func _on_convert_button_pressed() -> void:
	file_dialog.popup_centered()

func _on_charIconLoad_button_pressed() -> void:
	char_icon_file_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	current_char_folder = path.get_base_dir()
	print(current_char_folder)
	var file = FileAccess.open(path, FileAccess.READ)
	var data: Dictionary[String, Dictionary] = BasicIni.parse(file.get_as_text())
	for section in data:
		print(section)
		if section.to_lower() == "options":
			print(data[section])
			if data[section].keys().has("showname"):
				showname_edit.text = data[section]["showname"]
		if section.to_lower() == "emotions":
			var emotions = data[section]
			load_emotes_from_ini(emotions)
	load_char_icon_from_filepath(current_char_folder + "/char_icon.png")
	regenerate_buttons()

func load_char_icon_from_filepath(iconPath: String) -> void:
	var image = Image.new()
	image.load(iconPath)
	var image_texture: ImageTexture = ImageTexture.new()
	image_texture.set_image(image)
	character_icon.texture = image_texture

func load_emotes_from_ini(emoteDict: Dictionary) -> void:
	current_emotes.clear()
	for key in emoteDict:
		if key.to_lower() == "number":
			continue
		var value: String = emoteDict[key]
		print(key, ' = ', value)
		var emote_args: PackedStringArray = value.split("#", true, 4)
		if emote_args.size() < 4:
			push_warning("Misformatted char.ini: ", current_char_folder, ", ", key, " = ", value)
			continue
		# desk mod is not always included
		emote_args.resize(5)
		var emote: Emote = Emote.new(emote_args[0], emote_args[1], emote_args[2], emote_args[3], emote_args[4])
		current_emotes.append(emote)	


func regenerate_buttons():
	emote_list.clear()
	for i: int in current_emotes.size():
		var emote: Emote = current_emotes[i]
		var image_path = "%s/emotions/button%s_off.png" % [current_char_folder, i+1]
		var image = Image.new()
		image.load(image_path)
		var image_texture: ImageTexture = ImageTexture.new()
		image_texture.set_image(image)
		var at = emote_list.add_item(emote.display_name, image_texture)
		emote_list.set_item_metadata(at, emote)
		emote_list.set_item_tooltip(at, "%s: %s, %s" % [i+1, emote.pre, emote.idle])

func _on_emote_selected(idx: int):
	var emote: Emote = current_emotes[idx]
	var image_path = "%s/%s.png" % [current_char_folder, emote.idle]
	var image = Image.new()
	image.load(image_path)
	var image_texture: ImageTexture = ImageTexture.new()
	image_texture.set_image(image)
	preview_texture_rect.texture = image_texture
	#preview_node.calc_preview_height()
