extends Control

@onready var file_dialog: FileDialog = %FileDialog
@onready var open_ini_button: Button = %OpenIniButton
@onready var emote_list: ItemList = %EmoteList
@onready var character_icon: TextureRect = %CharIcon
@onready var char_folder_label: Label = %CharFolderLabel

# Options
@onready var charname_edit: LineEdit = %CharnameEdit
@onready var showname_edit: LineEdit = %ShownameEdit
@onready var showname_check: CheckBox = %ShownameCheck
@onready var side_edit: LineEdit = %SideEdit
@onready var blips_edit: LineEdit = %BlipsEdit
@onready var chat_edit: LineEdit = %ChatEdit
@onready var effects_edit: LineEdit = %EffectsEdit
@onready var realization_edit: LineEdit = %RealizationEdit
@onready var category_edit: LineEdit = %CategoryEdit
@onready var scaling_option: OptionButton = %ScalingOption

# Emote
@onready var number_spin_box: SpinBox = %NumberSpinBox
@onready var comment_edit: LineEdit = %CommentEdit
@onready var preanim_edit: LineEdit = %PreanimEdit
@onready var emote_edit: LineEdit = %EmoteEdit
@onready var modifier_option: OptionButton = %ModifierOption
@onready var deskmod_option: OptionButton = %DeskmodOption
@onready var sound_name_edit: LineEdit = %SoundNameEdit
@onready var sound_time_edit: SpinBox = %SoundTimeEdit
@onready var sound_loop_check: CheckBox = %SoundLoopCheck

# TODO: get these the heck outta the gui
@onready var world: Node2D = %World

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

const ANIMATED_EXTENSIONS: PackedStringArray = ["webp", "apng", "gif"]
const STATIC_EXTENSIONS: PackedStringArray = ["png"]
const SUPPORTED_EXTENSIONS: PackedStringArray = ANIMATED_EXTENSIONS + STATIC_EXTENSIONS

var current_emotes: Array[Emote] = []
var current_char_folder: String

var current_anim: AttorneyAnimation

var parsed_data: Dictionary[String, Dictionary]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	open_ini_button.pressed.connect(_on_open_ini_button_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	emote_list.item_selected.connect(_on_emote_selected)
	scaling_option.item_selected.connect(_on_scaling_selected)


func _on_open_ini_button_pressed() -> void:
	file_dialog.popup_centered()

func _on_char_icon_file_selected(file_path: String) -> void:
	load_char_icon_from_filepath(file_path)

func _on_file_selected(path: String) -> void:
	var char_folder: String = path.get_base_dir()
	current_emotes.clear()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	parsed_data = BasicIni.parse(file.get_as_text())
	if "emotions" in parsed_data:
		var emotions: Dictionary = parsed_data["emotions"]
		for key: String in emotions:
			if key.to_lower() == "number":
				continue
			var value: String = emotions[key]
			var emote_args: PackedStringArray = value.split("#", true)
			if emote_args.size() < 4:
				push_warning("Misformatted char.ini: ", char_folder, ", ", key, " = ", value)
				continue
			# desk mod is not always included
			emote_args.resize(5)
			var emote: Emote = Emote.new(emote_args[0], emote_args[1], emote_args[2], emote_args[3], emote_args[4])
			current_emotes.append(emote)
	if "options" in parsed_data:
		var options: Dictionary = parsed_data["options"]
		var char_name: String = ""
		var showname: String = ""
		var needs_showname: bool = true
		var side: String = ""
		var blips: String = ""
		var category: String = ""
		var scaling: String = ""
		var chat: String = ""
		var effects: String = ""
		var realization: String = ""
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
		charname_edit.text = char_name
		showname_edit.text = showname
		showname_check.button_pressed = needs_showname
		side_edit.text = side
		blips_edit.text = blips
		chat_edit.text = chat
		effects_edit.text = effects
		realization_edit.text = realization
		category_edit.text = category
		if scaling != "pixel":
			scaling_option.select(0)
		else:
			scaling_option.select(1)
	load_char_icon_from_filepath(char_folder + "/char_icon.png")
	current_char_folder = char_folder
	char_folder_label.text = current_char_folder.get_file()
	char_folder_label.tooltip_text = current_char_folder
	regenerate_buttons()


func regenerate_buttons() -> void:
	emote_list.clear()
	for i: int in current_emotes.size():
		var emote: Emote = current_emotes[i]
		var image_path: String = "%s/emotions/button%s_off.png" % [current_char_folder, i+1]
		var image: Image = Image.new()
		image.load(image_path)
		var image_texture: ImageTexture = ImageTexture.new()
		image_texture.set_image(image)
		var at: int = emote_list.add_item(emote.display_name, image_texture)
		emote_list.set_item_metadata(at, emote)
		emote_list.set_item_tooltip(at, "%s\n%s: %s, %s" % [emote.display_name, i+1, emote.pre, emote.idle])

func search_valid_idle_emote(char_folder: String, emote_name: String) -> String:
	for ext: String in SUPPORTED_EXTENSIONS:
		var try_path: String = "%s/%s.%s" % [char_folder, emote_name, ext]
		if FileAccess.file_exists(try_path):
			return try_path
		try_path = "%s/(a)%s.%s" % [char_folder, emote_name, ext]
		if FileAccess.file_exists(try_path):
			return try_path
	return ""

func _on_emote_selected(idx: int) -> void:
	number_spin_box.value = idx

	var emote: Emote = current_emotes[idx]
	comment_edit.text = emote.display_name
	preanim_edit.text = emote.pre
	emote_edit.text = emote.idle
	for i: int in modifier_option.item_count:
		var id: int = modifier_option.get_item_id(i)
		if id == emote.emote_mod:
			modifier_option.select(i)
			break
	for i: int in deskmod_option.item_count:
		var id: int = deskmod_option.get_item_id(i)
		if id == emote.desk_mod:
			deskmod_option.select(i)
			break

	var image_path: String = search_valid_idle_emote(current_char_folder, emote.idle)
	var file_extension: String = image_path.get_extension()
	if not image_path:
		return
	if file_extension in ANIMATED_EXTENSIONS:
		var magick: Magick = Magick.new()
		var frame_data: Array[Dictionary] = magick.get_frame_data(image_path)
		var directory: String = image_path.get_base_dir()
		var base_name: String = image_path.get_file().get_basename()
		var char_name: String = directory.substr(directory.rfind("/")+1)
		var frames_folder: String = ProjectSettings.globalize_path("user://frame_cache/%s/%s/" % [char_name, base_name])
		if not FileAccess.file_exists(frames_folder):
			magick.split_frames(image_path, frames_folder)
		#magick.split_frames(image_path)
		var lib: AnimationLibrary = world.animation_player.get_animation_library("")
		if current_anim:
			world.animation_player.stop()
			lib.remove_animation(current_anim.name)
			current_anim.queue_free()
		current_anim = AttorneyAnimation.new()
		current_anim.name = base_name
		current_anim.add_frames_from_folder(frames_folder)
		current_anim.initialize_from_frame_data(frame_data)

		if scaling_option.selected == 0:
			current_anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		elif scaling_option.selected == 1:
			current_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		world.add_child(current_anim)
		lib.add_animation(base_name, current_anim.animation)
		world.animation_player.play(base_name)
		return
	var image: Image = Image.new()
	image.load(image_path)
	var image_texture: ImageTexture = ImageTexture.new()
	image_texture.set_image(image)

func _on_scaling_selected(index: int) -> void:
	if current_anim:
		if index == 0:
			current_anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		elif index == 1:
			current_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var path = ProjectSettings.globalize_path("user://frame_cache/")
		remove_contents_of(path)

func remove_contents_of(directory: String) -> void:
	for dir_name in DirAccess.get_directories_at(directory):
		var dir_path: String = directory.path_join(dir_name)
		remove_contents_of(directory.path_join(dir_name))
		DirAccess.remove_absolute(dir_path)
	var dir = DirAccess.open(directory)
	for file in dir.get_files():
		dir.remove(file)

func load_char_icon_from_filepath(iconPath: String) -> void:
	var image = Image.new()
	image.load(iconPath)
	var image_texture: ImageTexture = ImageTexture.new()
	image_texture.set_image(image)
	character_icon.texture = image_texture
