extends Control

@onready var file_dialog: FileDialog = %FileDialog
@onready var image_dialog: FileDialog = %ImageDialog
@onready var file_dialog_save: FileDialog = %FileDialogSave
@onready var button_image_dialog: FileDialog = %ButtonImageDialog
@onready var confirmation_dialog: ConfirmationDialog = %ConfirmationDialog
@onready var install_magick_dialog: AcceptDialog = %InstallMagickDialog

@onready var new_button: Button = %NewButton
@onready var open_ini_button: Button = %OpenIniButton
@onready var save_button: Button = %SaveButton

@onready var emote_list: ItemList = %EmoteList
@onready var add_emote_button: Button = %AddEmoteButton

@onready var character_icon: TextureRect = %CharIcon
@onready var char_folder_label: Label = %CharFolderLabel

@onready var animation_buttons: HBoxContainer = %AnimationButtons
@onready var animation_option_button: OptionButton = %AnimationOptionButton

@onready var loop_pre_button: CheckButton = %LoopPreButton

@onready var loading_screen: ColorRect = %LoadingScreen

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
@onready var delete_emote_button: Button = %DeleteEmoteButton
@onready var comment_edit: LineEdit = %CommentEdit
@onready var preanim_edit: LineEdit = %PreanimEdit
@onready var emote_edit: LineEdit = %EmoteEdit
@onready var modifier_option: OptionButton = %ModifierOption
@onready var deskmod_option: OptionButton = %DeskmodOption
@onready var sound_name_edit: LineEdit = %SoundNameEdit
@onready var sound_time_edit: SpinBox = %SoundTimeEdit
@onready var sound_loop_check: CheckBox = %SoundLoopCheck
@onready var set_preanim_button: Button = %SetPreanimButton
@onready var set_emote_button: Button = %SetEmoteButton
@onready var off_button_icon: TextureRect = %OffButtonIcon
@onready var off_photo_button: Button = %OffPhotoButton
@onready var off_load_button: Button = %OffLoadButton
@onready var on_button_icon: TextureRect = %OnButtonIcon
@onready var on_photo_button: Button = %OnPhotoButton
@onready var on_load_button: Button = %OnLoadButton
@onready var emotes_fold: FoldableContainer = %EmotesFold
@onready var character_fold: FoldableContainer = %CharacterFold
@onready var emote_modifiers_fold: FoldableContainer = %EmoteModifiersFold
@onready var button_maker_check_button: CheckButton = %ButtonMakerCheckButton

# Button image buttons
@onready var button_image_buttons: Control = $HSplitContainer/CenterSplitContainer/ViewZone/ButtonImageButtons
@onready var load_bg_button: Button = %LoadBGButton
@onready var clear_bg_button: Button = %ClearBGButton
@onready var load_fg_button: Button = %LoadFGButton
@onready var clear_fg_button: Button = %ClearFGButton
@onready var load_mask_button: Button = %LoadMaskButton
@onready var clear_mask_button: Button = %ClearMaskButton
@onready var capture_button: Button = %CaptureButton

@onready var button_maker: Control = %ButtonMaker
@onready var off_button_panel: PanelContainer = %OffButtonPanel
@onready var on_button_panel: PanelContainer = %OnButtonPanel
@onready var button_previewer: ButtonPreviewer = %ButtonPreviewer
@onready var button_size_spin_box: SpinBox = %ButtonSizeSpinBox

# TODO: get these the heck outta the gui
@onready var world: Node2D = %World

@export var preview_height: float = 1.0

const PANEL_FOCUS = preload("uid://dloxm1fufhvem")
const PANEL_NO_FOCUS = preload("uid://cl656j0a88m6c")

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

var current_emote_number: int = 0
var current_character: Character

var current_anim: AttorneyAnimation

enum EmoteState {PRE, IDLE, TALK, POST}
var current_state: EmoteState = EmoteState.PRE

var parsed_data: Dictionary[String, Dictionary]

var is_image_pre: bool = false

enum ButtonImageType {
	BG,
	FG,
	MASK
}
var button_image_type: ButtonImageType = ButtonImageType.BG

var is_button_image_on: bool = false

var magick: Magick

const BUTTON_PLACEHOLDER: Texture = preload("uid://e8ms34nail52")

signal button_maker_toggled(toggled_on: bool)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	open_ini_button.pressed.connect(_on_open_ini_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	image_dialog.file_selected.connect(_on_image_selected)
	file_dialog_save.file_selected.connect(_on_save_file_selected)
	button_image_dialog.file_selected.connect(_on_button_image_file_selected)
	
	emote_list.item_selected.connect(_on_emote_selected)
	add_emote_button.pressed.connect(_on_add_emote_pressed)
	scaling_option.item_selected.connect(_on_scaling_selected)
	animation_option_button.item_selected.connect(_on_anim_state_selected)
	loop_pre_button.toggled.connect(_on_loop_pre_button_toggled)
	# Char sidemenu
	charname_edit.text_changed.connect(_on_char_name_changed)
	showname_edit.text_changed.connect(_on_char_showname_changed)
	showname_check.toggled.connect(_on_char_needShowname_changed)
	side_edit.text_changed.connect(_on_char_side_changed)
	blips_edit.text_changed.connect(_on_char_blips_changed)
	chat_edit.text_changed.connect(_on_char_chat_changed)
	effects_edit.text_changed.connect(_on_char_effects_changed)
	realization_edit.text_changed.connect(_on_char_realization_changed)
	category_edit.text_changed.connect(_on_char_category_changed)
	scaling_option.item_selected.connect(_on_char_scaling_changed)
	# Emote sidemenu
	set_preanim_button.pressed.connect(_on_set_preanim_button_pressed)
	set_emote_button.pressed.connect(_on_set_emote_button_pressed)
	number_spin_box.value_changed.connect(_on_emote_number_changed)
	delete_emote_button.pressed.connect(_on_delete_emote_pressed)
	comment_edit.text_changed.connect(_on_emote_name_changed)
	preanim_edit.text_submitted.connect(_on_preanim_edit_changed)
	preanim_edit.focus_exited.connect(_on_preanim_lost_focus)
	emote_edit.text_submitted.connect(_on_emote_edit_changed)
	emote_edit.focus_exited.connect(_on_emote_lost_focus)
	modifier_option.item_selected.connect(_on_emote_mod_changed)
	deskmod_option.item_selected.connect(_on_emote_deskmod_changed)
	sound_name_edit.text_changed.connect(_on_emote_sound_changed)
	sound_time_edit.value_changed.connect(_on_emote_soundTime_changed)
	sound_loop_check.toggled.connect(_on_emote_soundLoop_changed)
	off_photo_button.pressed.connect(_on_off_photo_button_pressed)
	on_photo_button.pressed.connect(_on_on_photo_button_pressed)
	# Button image buttons
	load_bg_button.pressed.connect(_on_load_bg_button_pressed)
	clear_bg_button.pressed.connect(_on_clear_bg_button_pressed)
	load_fg_button.pressed.connect(_on_load_fg_button_pressed)
	clear_fg_button.pressed.connect(_on_clear_fg_button_pressed)
	load_mask_button.pressed.connect(_on_load_mask_button_pressed)
	clear_mask_button.pressed.connect(_on_clear_mask_button_pressed)

	emotes_fold.folding_changed.connect(_on_emotes_folding_changed)
	character_fold.folding_changed.connect(_on_character_folding_changed)
	emote_modifiers_fold.folding_changed.connect(_on_emote_modifiers_folding_changed)

	button_maker_check_button.toggled.connect(_on_button_maker_toggled)

	capture_button.pressed.connect(_on_capture_pressed)

	magick = Magick.new()
	var magick_real: bool = magick.test_magick()
	if not magick_real:
		install_magick_dialog.popup_centered()


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var path = ProjectSettings.globalize_path("user://frame_cache/")
		remove_contents_of(path)


func _on_open_ini_button_pressed() -> void:
	file_dialog.popup_centered()


func _on_set_preanim_button_pressed() -> void:
	is_image_pre = true
	image_dialog.current_dir = current_character.get_folder()
	image_dialog.popup_centered()


func _on_set_emote_button_pressed() -> void:
	is_image_pre = false
	image_dialog.current_dir = current_character.get_folder()
	image_dialog.popup_centered()


func _on_char_icon_file_selected(file_path: String) -> void:
	load_char_icon_from_filepath(file_path)


func _on_file_selected(path: String) -> void:
	# Create a new character
	clear_world()
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
	number_spin_box.set_block_signals(true)
	number_spin_box.max_value = current_character.emotes.size()
	number_spin_box.set_block_signals(false)
	var char_folder: String = path.get_base_dir()
	load_char_icon_from_filepath(char_folder + "/char_icon.png")
	char_folder_label.text = char_folder.get_basename().get_file()
	char_folder_label.tooltip_text = char_folder
	regenerate_buttons()
	animation_option_button.disabled = false


func _on_char_name_changed(new_text: String) -> void:
	current_character.char_name = new_text


func _on_char_showname_changed(new_text: String) -> void:
	current_character.showname = new_text


func _on_char_needShowname_changed(toggled_on: bool) -> void:
	current_character.needs_showname = toggled_on


func _on_char_side_changed(new_text: String) -> void:
	current_character.side = new_text


func _on_char_blips_changed(new_text: String) -> void:
	current_character.blips = new_text


func _on_char_chat_changed(new_text: String) -> void:
	current_character.chat = new_text


func _on_char_effects_changed(new_text: String) -> void:
	current_character.effects = new_text


func _on_char_realization_changed(new_text: String) -> void:
	current_character.realization = new_text


func _on_char_category_changed(new_text: String) -> void:
	current_character.category = new_text


func _on_char_scaling_changed(index: int) -> void:
	current_character.scaling = scaling_option.get_item_text(index)


func _on_preanim_edit_changed(new_text: String) -> void:
	is_image_pre = true
	_on_image_selected(new_text)


func _on_preanim_lost_focus() -> void:
	if preanim_edit.text == current_character.emotes[current_emote_number].pre:
		return
	is_image_pre = true
	_on_image_selected(preanim_edit.text)


func _on_emote_edit_changed(new_text: String) -> void:
	is_image_pre = false
	_on_image_selected(new_text)


func _on_emote_lost_focus() -> void:
	if emote_edit.text == current_character.emotes[current_emote_number].idle:
		return
	is_image_pre = false
	_on_image_selected(emote_edit.text)


func _on_image_selected(path: String) -> void:
	if is_image_pre:
		preanim_edit.text = get_emote_path(path)
		current_character.emotes[current_emote_number].pre = get_emote_path(path)
	else:
		emote_edit.text = get_emote_path(path)
		current_character.emotes[current_emote_number].idle = get_emote_path(path)
	_on_emote_selected(current_emote_number)


func _on_add_emote_pressed() -> void:
	if not current_character:
		return
	var emote: Emote = Emote.new("Blank")
	current_character.emotes.append(emote)
	number_spin_box.set_block_signals(true)
	number_spin_box.max_value = current_character.emotes.size()
	number_spin_box.set_block_signals(false)
	set_emote_button_images(emote, current_character.get_folder() + "/emotions/", current_character.emotes.size())
	add_emote_list_button(emote)


func get_emote_path(filePath: String) -> String:
	var result = filePath.get_basename().trim_prefix(current_character.get_folder() + "/")
	result = result.trim_prefix("(a)").trim_prefix("(b)").trim_prefix("(c)")
	return result


func _on_emote_name_changed(new_text: String) -> void:
	current_character.emotes[current_emote_number].display_name = new_text
	emote_list.set_item_text(current_emote_number, new_text)


func _on_emote_mod_changed(index: int) -> void:
	current_character.emotes[current_emote_number].emote_mod = modifier_option.get_item_id(index) as Emote.EmoteMod


func _on_emote_deskmod_changed(index: int) -> void:
	current_character.emotes[current_emote_number].desk_mod = deskmod_option.get_item_id(index) as Emote.DeskMod


func _on_emote_sound_changed(new_text: String) -> void:
	current_character.emotes[current_emote_number].sound_name = new_text


func _on_emote_soundTime_changed(value: float) -> void:
	current_character.emotes[current_emote_number].sound_time = int(value)


func _on_emote_soundLoop_changed(toggled_on: bool) -> void:
	current_character.emotes[current_emote_number].sound_loop = toggled_on


func _on_emotes_folding_changed(is_folded: bool) -> void:
	%CenterSplitContainer.collapsed = is_folded


func _on_character_folding_changed(_is_folded: bool) -> void:
	if character_fold.folded:
		character_fold.size_flags_vertical = Control.SIZE_FILL
	else:
		character_fold.size_flags_vertical = Control.SIZE_EXPAND_FILL
	%LeftSplitContainer.collapsed = character_fold.folded or emote_modifiers_fold.folded


func _on_emote_modifiers_folding_changed(_is_folded: bool) -> void:
	%LeftSplitContainer.collapsed = character_fold.folded or emote_modifiers_fold.folded


func _on_button_maker_toggled(toggled_on: bool) -> void:
	button_maker.visible = toggled_on
	button_maker_toggled.emit(toggled_on)


func regenerate_buttons() -> void:
	emote_list.clear()
	for i: int in current_character.emotes.size():
		var emote: Emote = current_character.emotes[i]
		set_emote_button_images(emote, current_character.get_folder() + "/emotions/", i)
		add_emote_list_button(emote)


func add_emote_list_button(emote: Emote) -> void:
	var icon: Texture = emote.image_off
	if icon == null:
		icon = BUTTON_PLACEHOLDER
	var at: int = emote_list.add_item(emote.display_name, icon)
	emote_list.set_item_metadata(at, emote)
	emote_list.set_item_tooltip(at, "%s\n%s: %s, %s" % [emote.display_name, at + 1, emote.pre, emote.idle])


func set_emote_button_images(emote: Emote, folderPath: String, idx: int) -> void:
	var button_path = folderPath + "button" + str(idx + 1)
	var button_off_path: String = button_path + "_off.png"
	var button_on_path: String = button_path + "_on.png"
	if FileAccess.file_exists(button_off_path):
		emote.image_off = ImageTexture.create_from_image(Image.load_from_file(button_off_path))
	if FileAccess.file_exists(button_on_path):
		emote.image_on = ImageTexture.create_from_image(Image.load_from_file(button_on_path))


func search_valid_emote(char_folder: String, emote_name: String, state: String) -> String:
	var try_path: String
	for ext: String in SUPPORTED_EXTENSIONS:
		if state == "idle":
			try_path = "%s/(a)%s.%s" % [char_folder, emote_name, ext]
		if state == "talk":
			try_path = "%s/(b)%s.%s" % [char_folder, emote_name, ext]
		if state == "post":
			try_path = "%s/(c)%s.%s" % [char_folder, emote_name, ext]
			if not FileAccess.file_exists(try_path):
				return ""
		if FileAccess.file_exists(try_path):
			return try_path
		else:
			try_path = "%s/%s.%s" % [char_folder, emote_name, ext]
		if FileAccess.file_exists(try_path):
			return try_path
	return ""


func _on_emote_selected(idx: int) -> void:
	if idx < 0 or idx >= current_character.emotes.size():
		return
	var previous_emote_number: int = current_emote_number
	current_emote_number = idx
	emote_list.select(current_emote_number)
	number_spin_box.set_block_signals(true)
	number_spin_box.value = idx + 1
	number_spin_box.set_block_signals(false)
	var emote: Emote = current_character.emotes[idx]
	comment_edit.text = emote.display_name
	preanim_edit.text = emote.pre
	emote_edit.text = emote.idle
	deskmod_option.selected = emote.desk_mod
	sound_name_edit.text = emote.sound_name
	sound_time_edit.value = emote.sound_time
	sound_loop_check.button_pressed = emote.sound_loop
	# Set previous emote's button to off state
	if previous_emote_number >= 0 and previous_emote_number < current_character.emotes.size():
		var previous_emote: Emote = current_character.emotes[previous_emote_number]
		if previous_emote and previous_emote.image_off != null:
			emote_list.set_item_icon(previous_emote_number, previous_emote.image_off)
	var icon: Texture = emote.image_off
	if icon == null:
		icon = BUTTON_PLACEHOLDER
	if emote.image_on != null:
		icon = emote.image_on
	emote_list.set_item_icon(current_emote_number, icon)
	off_button_icon.texture = emote.image_off
	on_button_icon.texture = emote.image_on
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
	var pre_image_path: String = search_valid_emote(current_character.get_folder(), emote.pre, "pre")
	var idle_image_path: String = search_valid_emote(current_character.get_folder(), emote.idle, "idle")
	var talk_image_path: String = search_valid_emote(current_character.get_folder(), emote.idle, "talk")
	var post_image_path: String = search_valid_emote(current_character.get_folder(), emote.idle, "post")
	animation_option_button.disabled = false
	animation_option_button.set_item_disabled(0, true)
	animation_option_button.set_item_disabled(1, true)
	animation_option_button.set_item_disabled(2, true)
	animation_option_button.set_item_disabled(3, true)
	loading_screen.show()
	if pre_image_path:
		await load_image_file(pre_image_path)
		animation_option_button.set_item_disabled(0, false)
	if idle_image_path:
		await load_image_file(idle_image_path)
		animation_option_button.set_item_disabled(1, false)
	if talk_image_path:
		await load_image_file(talk_image_path)
		animation_option_button.set_item_disabled(2, false)
	if post_image_path:
		await load_image_file(post_image_path)
		animation_option_button.set_item_disabled(3, false)
	loading_screen.hide()
	if emote.emote_mod == Emote.EmoteMod.PREANIM:
		_on_anim_state_selected(EmoteState.PRE)
	else:
		_on_anim_state_selected(EmoteState.IDLE)


func load_image_file(image_path: String):
	var local_path: String = image_path.trim_prefix(current_character.get_folder() + "/").get_basename()
	var node_name: String = local_path.replace("/", "|")
	if is_instance_valid(world.get_node_or_null(node_name)):
		return
	var file_extension: String = image_path.get_extension()
	if file_extension in ANIMATED_EXTENSIONS:
		await handle_animated_file(image_path)
	if file_extension in STATIC_EXTENSIONS:
		handle_static_file(image_path)


func handle_animated_file(image_path: String) -> void:
	var frame_data: Array[Dictionary] = await magick.get_threaded_frame_data(image_path)
	var directory: String = image_path.get_base_dir()
	var base_name: String = image_path.get_file().get_basename()
	var local_path: String = image_path.trim_prefix(current_character.get_folder() + "/").get_basename()
	var char_name: String = directory.get_file()
	var frames_folder: String = ProjectSettings.globalize_path("user://frame_cache/%s/%s/" % [char_name, base_name])
	if not FileAccess.file_exists(frames_folder):
		magick.split_frames(image_path, frames_folder)
	var attorney_anim: AttorneyAnimation = AttorneyAnimation.new()
	attorney_anim.add_frames_from_folder(frames_folder)
	attorney_anim.initialize_from_frame_data(local_path, frame_data)
	attorney_anim.name = local_path.replace("/", "|")
	if scaling_option.selected == 0:
		world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	elif scaling_option.selected == 1:
		world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(attorney_anim)

# TODO: static image file should still be treated as a single-frame AttorneyAnimation
func handle_static_file(image_path: String) -> void:
	var image = Image.load_from_file(image_path)
	var image_texture = ImageTexture.create_from_image(image)
	var sprite = Sprite2D.new()
	sprite.texture = image_texture
	sprite.set_texture(image_texture)
	var local_path: String = image_path.trim_prefix(current_character.get_folder() + "/").get_basename()
	sprite.name = local_path.replace("/", "|")
	world.add_child(sprite)


func clear_world() -> void:
	animation_buttons.set_animation_player(null)
	loop_pre_button.disabled = true
	animation_option_button.disabled = true
	for child in world.get_children():
		child.queue_free()


func _on_anim_state_selected(index: int):
	animation_option_button.select(index)
	current_state = index as EmoteState
	var emote_name: String = emote_edit.text
	var prefix: String = ""
	match current_state:
		EmoteState.PRE:
			emote_name = preanim_edit.text
		EmoteState.IDLE:
			prefix = "(a)"
		EmoteState.TALK:
			prefix = "(b)"
		EmoteState.POST:
			prefix = "(c)"
	emote_name = emote_name.replace("/", "|")
	animation_buttons.set_animation_player(null)
	for child: Node2D in world.get_children():
		child.hide()
		if child is AttorneyAnimation:
			var ao_anim: AttorneyAnimation = child
			if ao_anim.animation_player.animation_finished.is_connected(_on_pre_finished):
				ao_anim.animation_player.animation_finished.disconnect(_on_pre_finished)
			ao_anim.animation_player.stop()
			if child.name == prefix + emote_name:
				ao_anim.show()
				animation_buttons.set_animation_player(ao_anim.animation_player)
				loop_pre_button.disabled = false
				if current_state == EmoteState.PRE:
					ao_anim.animation_player.animation_finished.connect(_on_pre_finished, CONNECT_ONE_SHOT)
					if loop_pre_button.button_pressed:
						ao_anim.animation.loop_mode = Animation.LOOP_LINEAR
					else:
						ao_anim.animation.loop_mode = Animation.LOOP_NONE
				ao_anim.animation_player.play(ao_anim.name)
				current_anim = ao_anim
				animation_buttons.show()
		else:
			# no prefix checked
			if child.name == emote_name:
				child.show()
				animation_buttons.hide()


func _on_pre_finished(_anim_name: StringName) -> void:
	# wait a frame so we don't create a frame where nothing is shown
	await get_tree().process_frame
	_on_anim_state_selected(EmoteState.IDLE)


func _on_loop_pre_button_toggled(toggled_on: bool) -> void:
	if not current_anim:
		return
	# preanim is NOT selected
	if animation_option_button.selected != 0:
		return
	if toggled_on:
		current_anim.animation.loop_mode = Animation.LOOP_LINEAR
	else:
		current_anim.animation.loop_mode = Animation.LOOP_NONE


func _on_scaling_selected(index: int) -> void:
	if index == 0:
		world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	elif index == 1:
		world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _on_emote_number_changed(value: float) -> void:
	var index_from: int = current_emote_number
	var index_to: int = int(value) - 1
	current_character.emotes.insert(index_to, current_character.emotes.pop_at(index_from))
	emote_list.move_item(index_from, index_to)
	current_emote_number = index_to


func _on_delete_emote_pressed() -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		delete_emote(current_emote_number)
		return
	confirmation_dialog.title = "Delete Emote?"
	confirmation_dialog.dialog_text = """
Are you sure you want to delete this emote?
There is no undo-redo yet!! (Hold Shift to skip this prompt next time)
	"""
	confirmation_dialog.ok_button_text = "Delete!"
	confirmation_dialog.popup_centered()
	confirmation_dialog.confirmed.connect(
		_on_delete_emote_confirmed,
		CONNECT_ONE_SHOT
	)
	confirmation_dialog.canceled.connect(
		_on_delete_emote_canceled,
		CONNECT_ONE_SHOT
	)


func _on_delete_emote_confirmed() -> void:
	if confirmation_dialog.confirmed.is_connected(_on_delete_emote_confirmed):
		confirmation_dialog.confirmed.disconnect(_on_delete_emote_confirmed)
	if confirmation_dialog.canceled.is_connected(_on_delete_emote_canceled):
		confirmation_dialog.canceled.disconnect(_on_delete_emote_canceled)
	delete_emote(current_emote_number)


func _on_delete_emote_canceled() -> void:
	if confirmation_dialog.confirmed.is_connected(_on_delete_emote_confirmed):
		confirmation_dialog.confirmed.disconnect(_on_delete_emote_confirmed)
	if confirmation_dialog.canceled.is_connected(_on_delete_emote_canceled):
		confirmation_dialog.canceled.disconnect(_on_delete_emote_canceled)


func delete_emote(idx: int) -> void:
	current_character.emotes.remove_at(idx)
	number_spin_box.set_block_signals(true)
	number_spin_box.max_value = current_character.emotes.size()
	number_spin_box.set_block_signals(false)
	emote_list.remove_item(idx)
	_on_emote_selected(clampi(0, idx-1, current_character.emotes.size()))


func remove_contents_of(directory: String) -> void:
	for dir_name in DirAccess.get_directories_at(directory):
		var dir_path: String = directory.path_join(dir_name)
		remove_contents_of(directory.path_join(dir_name))
		DirAccess.remove_absolute(dir_path)
	var dir = DirAccess.open(directory)
	for file in dir.get_files():
		dir.remove(file)


func load_char_icon_from_filepath(iconPath: String) -> void:
	var image = Image.load_from_file(iconPath)
	var image_texture = ImageTexture.create_from_image(image)
	character_icon.texture = image_texture


func _on_save_button_pressed() -> void:
	file_dialog_save.current_dir = current_character.get_folder()
	file_dialog_save.popup_centered()


func _on_save_file_selected(path: String) -> void:
	var ini_string: String = BasicIni.make_char_ini(current_character.save_data())
	var save_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	save_file.store_string(ini_string)
	current_character.ini_path = path
	var save_folder: String = path.get_base_dir()
	# SAVE BUTTONS
	# TODO: move this somewhere more appropriate!!
	var emotions_folder: String = save_folder + "/emotions/"
	if DirAccess.dir_exists_absolute(emotions_folder):
		confirmation_dialog.title = "Overwrite Buttons?"
		confirmation_dialog.dialog_text = """
Warning: /emotions/ folder already exists and will be overwritten.
If you press "Accept", an /_old_emotions/ folder will be created as backup.
If /_old_emotions/ already exists, all the files inside of it will also be overwritten!
		"""
		confirmation_dialog.ok_button_text = "Accept"
		confirmation_dialog.popup_centered()
		confirmation_dialog.confirmed.connect(
			_on_emotions_overwrite_confirmed.bind(save_folder),
			CONNECT_ONE_SHOT
		)
		confirmation_dialog.canceled.connect(
			_on_emotions_overwrite_cancelled,
			CONNECT_ONE_SHOT
		)
		return
	save_buttons(save_folder)


func _on_emotions_overwrite_confirmed(save_folder: String) -> void:
	if confirmation_dialog.confirmed.is_connected(_on_emotions_overwrite_confirmed):
		confirmation_dialog.confirmed.disconnect(_on_emotions_overwrite_confirmed)
	if confirmation_dialog.canceled.is_connected(_on_emotions_overwrite_cancelled):
		confirmation_dialog.canceled.disconnect(_on_emotions_overwrite_cancelled)
	save_buttons(save_folder)


func _on_emotions_overwrite_cancelled() -> void:
	if confirmation_dialog.confirmed.is_connected(_on_emotions_overwrite_confirmed):
		confirmation_dialog.confirmed.disconnect(_on_emotions_overwrite_confirmed)
	if confirmation_dialog.canceled.is_connected(_on_emotions_overwrite_cancelled):
		confirmation_dialog.canceled.disconnect(_on_emotions_overwrite_cancelled)


func save_buttons(path: String) -> void:
	var emotions_folder: String = path + "/emotions/"
	if DirAccess.dir_exists_absolute(emotions_folder):
		var backup_folder: String = path + "/_old_emotions/"
		DirAccess.make_dir_absolute(backup_folder)
		for file: String in DirAccess.get_files_at(emotions_folder):
			var input_path: String = emotions_folder + file
			var output_path: String = backup_folder + file
			if FileAccess.file_exists(output_path):
				DirAccess.remove_absolute(output_path)
			DirAccess.rename_absolute(input_path, output_path)
	DirAccess.make_dir_absolute(emotions_folder)
	for idx: int in current_character.emotes.size():
		var emote: Emote = current_character.emotes[idx]
		var button_path = emotions_folder + "button" + str(idx + 1)
		if emote.image_off:
			emote.image_off.get_image().save_png(button_path + "_off.png")
		if emote.image_on:
			emote.image_on.get_image().save_png(button_path + "_on.png")

func _on_button_image_file_selected(path: String) -> void:
	var image = Image.load_from_file(path)
	var texture = ImageTexture.create_from_image(image)
	match button_image_type:
		ButtonImageType.BG:
			button_previewer.button_bg.texture = texture
		ButtonImageType.FG:
			button_previewer.button_fg.texture = texture
		ButtonImageType.MASK:
			button_previewer.button_mask.texture = texture


func _on_load_bg_button_pressed() -> void:
	button_image_type = ButtonImageType.BG
	button_image_dialog.current_dir = current_character.get_folder()
	button_image_dialog.popup_centered()

func _on_clear_bg_button_pressed() -> void:
	button_previewer.button_bg.texture = null

func _on_load_fg_button_pressed() -> void:
	button_image_type = ButtonImageType.FG
	button_image_dialog.current_dir = current_character.get_folder()
	button_image_dialog.popup_centered()

func _on_clear_fg_button_pressed() -> void:
	button_previewer.button_fg.texture = null


func _on_load_mask_button_pressed() -> void:
	button_image_type = ButtonImageType.MASK
	button_image_dialog.current_dir = current_character.get_folder()
	button_image_dialog.popup_centered()


func _on_clear_mask_button_pressed() -> void:
	button_previewer.button_mask.texture = null


func _on_off_photo_button_pressed() -> void:
	is_button_image_on = false
	off_button_panel.add_theme_stylebox_override(&"panel", PANEL_FOCUS)
	on_button_panel.add_theme_stylebox_override(&"panel", PANEL_NO_FOCUS)

func _on_on_photo_button_pressed() -> void:
	is_button_image_on = true
	off_button_panel.add_theme_stylebox_override(&"panel", PANEL_NO_FOCUS)
	on_button_panel.add_theme_stylebox_override(&"panel", PANEL_FOCUS)


const EMOTE_MASK = preload("uid://c0xa6gbbd2q6y")
const EVI_BORDER = preload("uid://urw1u54y0xkx")

func _on_capture_pressed() -> void:
	var button_icon: TextureRect = off_button_icon
	if is_button_image_on:
		button_icon = on_button_icon
	button_previewer.sub_viewport.set_canvas_cull_mask_bit(1, false)
	button_previewer.button_mask.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
	button_previewer.button_mask.self_modulate = Color.TRANSPARENT
	await RenderingServer.frame_post_draw
	var button_size: int = int(button_size_spin_box.value)
	var screencap: Image = button_previewer.sub_viewport.get_texture().get_image()
	if screencap.get_size().x != button_size:
		screencap.resize(button_size, button_size, Image.INTERPOLATE_LANCZOS)
	var image: Image = screencap
	if button_previewer.button_bg.texture != null:
		image = button_previewer.button_bg.texture.get_image()
		# Ensure all images have alpha channels
		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)
		if image.get_size().x != button_size:
			image.resize(button_size, button_size, Image.INTERPOLATE_CUBIC)
		image.blend_rect(screencap, Rect2i(Vector2i(0, 0), screencap.get_size()), Vector2i(0, 0))

	if button_previewer.button_fg.texture != null:
		var fg_image = button_previewer.button_fg.texture.get_image()
		# Ensure all images have alpha channels
		if fg_image.get_format() != Image.FORMAT_RGBA8:
			fg_image.convert(Image.FORMAT_RGBA8)
		if fg_image.get_size().x != button_size:
			fg_image.resize(button_size, button_size, Image.INTERPOLATE_BILINEAR)
		image.blend_rect(fg_image, Rect2i(Vector2i(0, 0), screencap.get_size()), Vector2i(0, 0))

	# I couldn't figure out why blend_rect_mask didn't work so I'll instead just go
	# pixel by pixel, performance doesn't matter too much here and usually buttons are
	# smol anyway
	if button_previewer.button_mask.texture != null:
		var mask: Image = button_previewer.button_mask.texture.get_image()
		if mask.get_size().x != button_size:
			mask.resize(button_size, button_size, Image.INTERPOLATE_CUBIC)
		# Ensure all images have alpha channels
		if mask.get_format() != Image.FORMAT_RGBA8:
			mask.convert(Image.FORMAT_RGBA8)
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var mask_pixel: Color = mask.get_pixel(x, y)
				var source_pixel: Color = image.get_pixel(x, y)
				source_pixel.a = min(mask_pixel.a, source_pixel.a)
				image.set_pixel(x, y, source_pixel)

	# Set the button textures
	var image_texture: ImageTexture = ImageTexture.create_from_image(image)
	button_icon.texture = image_texture
	var emote: Emote = current_character.emotes[current_emote_number]
	if is_button_image_on:
		emote.image_on = image_texture
	else:
		emote.image_off = image_texture
	_on_emote_selected(current_emote_number)
	button_previewer.sub_viewport.set_canvas_cull_mask_bit(1, true)
	button_previewer.button_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	button_previewer.button_mask.self_modulate = Color.WHITE
