extends Control

@onready var file_dialog: FileDialog = %FileDialog
@onready var image_dialog: FileDialog = %ImageDialog
@onready var file_dialog_save: FileDialog = %FileDialogSave
@onready var new_button: Button = %NewButton
@onready var open_ini_button: Button = %OpenIniButton
@onready var save_button: Button = %SaveButton
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
@onready var preanim_button: Button = %PreanimButton
@onready var emote_button: Button = %EmoteButton

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

var current_emote_number: int = -1
var current_character: Character

var current_anim: AttorneyAnimation

var parsed_data: Dictionary[String, Dictionary]

var is_image_pre: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	open_ini_button.pressed.connect(_on_open_ini_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	image_dialog.file_selected.connect(_on_image_selected)
	file_dialog_save.file_selected.connect(_on_save_file_selected)
	emote_list.item_selected.connect(_on_emote_selected)
	scaling_option.item_selected.connect(_on_scaling_selected)
	preanim_button.pressed.connect(_on_preanim_button_pressed)
	emote_button.pressed.connect(_on_emote_button_pressed)
	number_spin_box.value_changed.connect(_on_emote_number_changed)


func _on_open_ini_button_pressed() -> void:
	file_dialog.popup_centered()

func _on_preanim_button_pressed() -> void:
	is_image_pre = true
	image_dialog.current_dir = current_character.get_folder()
	image_dialog.popup_centered()

func _on_emote_button_pressed() -> void:
	is_image_pre = false
	image_dialog.current_dir = current_character.get_folder()
	image_dialog.popup_centered()

func _on_char_icon_file_selected(file_path: String) -> void:
	load_char_icon_from_filepath(file_path)

func _on_file_selected(path: String) -> void:
	# Create a new character
	current_character = Character.new()
	current_character.ini_path = path
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	parsed_data = BasicIni.parse(file.get_as_text())
	# Load the data for the character!
	current_character.load_data(parsed_data)
	
	charname_edit.text = current_character.char_name
	showname_edit.text = current_character.showname
	showname_check.button_pressed = current_character.needs_showname
	side_edit.text = current_character.side
	blips_edit.text = current_character.blips
	chat_edit.text = current_character.chat
	effects_edit.text = current_character.effects
	realization_edit.text = current_character.realization
	category_edit.text = current_character.category
	if current_character.scaling != "pixel":
		scaling_option.select(0)
	else:
		scaling_option.select(1)
	number_spin_box.max_value = current_character.emotes.size() - 1
	
	var char_folder: String = path.get_base_dir()
	load_char_icon_from_filepath(char_folder + "/char_icon.png")
	char_folder_label.text = char_folder.get_basename().get_file()
	char_folder_label.tooltip_text = char_folder
	regenerate_buttons()

func _on_image_selected(path: String) -> void:
	if is_image_pre:
		preanim_edit.text = get_emote_path(path)
	else:
		emote_edit.text = get_emote_path(path)

func get_emote_path(filePath: String) -> String:
	print(filePath)
	var result = filePath.get_slice(".", 0).trim_prefix(current_character.get_folder() + "/")
	print(result)
	result = result.trim_prefix("(a)").trim_prefix("(b)")
	print(result)
	return result

func regenerate_buttons() -> void:
	emote_list.clear()
	for i: int in current_character.emotes.size():
		var emote: Emote = current_character.emotes[i]
		var image_path: String = "%s/emotions/button%s_off.png" % [current_character.get_folder(), i+1]
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
	current_emote_number = idx
	number_spin_box.set_block_signals(true)
	number_spin_box.value = idx
	number_spin_box.set_block_signals(false)
	var emote: Emote = current_character.emotes[idx]
	comment_edit.text = emote.display_name
	preanim_edit.text = emote.pre
	emote_edit.text = emote.idle
	deskmod_option.selected = emote.desk_mod
	sound_name_edit.text = emote.sound_name
	sound_time_edit.value = emote.sound_time
	sound_loop_check.button_pressed = emote.sound_loop
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
	var image_path: String = search_valid_idle_emote(current_character.get_folder(), emote.idle)
	if not image_path:
		return
	var file_extension: String = image_path.get_extension()
	# TODO: Cache all this somehow
	if file_extension in ANIMATED_EXTENSIONS:
		var magick: Magick = Magick.new()
		var frame_data: Array[Dictionary] = magick.get_frame_data(image_path)
		var directory: String = image_path.get_base_dir()
		var base_name: String = image_path.get_file().get_basename()
		var char_name: String = directory.get_file()
		var frames_folder: String = ProjectSettings.globalize_path("user://frame_cache/%s/%s/" % [char_name, base_name])
		if not FileAccess.file_exists(frames_folder):
			magick.split_frames(image_path, frames_folder)
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

func _on_emote_number_changed(value: float) -> void:
	var index_from: int = current_emote_number
	var index_to: int = int(value)
	current_character.emotes.insert(index_to, current_character.emotes.pop_at(index_from))
	emote_list.move_item(index_from, index_to)
	current_emote_number = index_to

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

func _on_save_button_pressed() -> void:
	file_dialog_save.current_dir = current_character.get_folder()
	file_dialog_save.popup_centered()

func _on_save_file_selected(path: String) -> void:
	var ini_string: String = BasicIni.make_char_ini(current_character.save_data())
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	save_file.store_string(ini_string)
