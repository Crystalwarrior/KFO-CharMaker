extends Control

@onready var file_dialog: FileDialog = %FileDialog
@onready var convert_button: Button = %ConvertButton
@onready var emote_list: ItemList = %EmoteList

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	convert_button.pressed.connect(_on_convert_button_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	emote_list.item_selected.connect(_on_emote_selected)

func _on_convert_button_pressed() -> void:
	file_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	var char_folder: String = path.get_base_dir()
	print(char_folder)

	current_emotes.clear()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var data: Dictionary[String, Dictionary] = BasicIni.parse(file.get_as_text())
	for section: String in data:
		print(section)
		if section.to_lower() == "emotions":
			var emotions: Dictionary = data[section]
			for key: String in emotions:
				if key.to_lower() == "number":
					continue
				var value: String = emotions[key]
				print(key, ' = ', value)
				var emote_args: PackedStringArray = value.split("#", true, 4)
				if emote_args.size() < 4:
					push_warning("Misformatted char.ini: ", char_folder, ", ", key, " = ", value)
					continue
				# desk mod is not always included
				emote_args.resize(5)
				var emote: Emote = Emote.new(emote_args[0], emote_args[1], emote_args[2], emote_args[3], emote_args[4])
				current_emotes.append(emote)

	current_char_folder = char_folder
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
		emote_list.set_item_tooltip(at, "%s: %s, %s" % [i+1, emote.pre, emote.idle])

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
	var emote: Emote = current_emotes[idx]
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
		print(frame_data)
		#magick.split_frames(image_path)
		var lib: AnimationLibrary = %AnimationPlayer.get_animation_library("")
		if current_anim:
			%AnimationPlayer.stop()
			lib.remove_animation(current_anim.name)
			current_anim.queue_free()
		current_anim = AttorneyAnimation.new()
		current_anim.name = base_name
		current_anim.add_frames_from_folder(frames_folder)
		current_anim.initialize_from_frame_data(frame_data)
		add_child(current_anim)
		lib.add_animation(base_name, current_anim.animation)
		print(lib.has_animation(base_name))
		%AnimationPlayer.play(base_name)
		return
	var image: Image = Image.new()
	image.load(image_path)
	var image_texture: ImageTexture = ImageTexture.new()
	image_texture.set_image(image)

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
