## Main character converter scene. Handles character INI loading/saving, emote
## management, animation preview, and button image capture.
class_name CharConverter
extends Control

#region Signals

## Emitted when the button maker panel is shown or hidden.
signal button_maker_toggled(toggled_on: bool)

#endregion

#region Enums

## Animation states corresponding to preanim, idle, talk, post-talking.
enum EmoteState {
	PRE,
	IDLE,
	TALK,
	POST,
}

## Which type of button image layer is being loaded (background, foreground, mask).
enum ButtonImageType {
	BG,
	FG,
	MASK,
}

#endregion

#region Constants

const PANEL_FOCUS: StyleBox = preload("uid://dloxm1fufhvem")
const PANEL_NO_FOCUS: StyleBox = preload("uid://cl656j0a88m6c")

const CHAR_ICON_BORDER: Texture2D = preload("uid://b5s50jkyeiod0")

const BUTTON_PLACEHOLDER: Texture2D = preload("uid://e8ms34nail52")

const EMOTE_MASK: Texture2D = preload("uid://c0xa6gbbd2q6y")
const EVI_BORDER: Texture2D = preload("uid://urw1u54y0xkx")

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

#endregion

#region Variables

@export var preview_height: float = 1.0

var position_offset_normal: Vector2 = Vector2(0.0, 0.0)

var current_emote_number: int = 0
var current_character: Character

var current_anim: AttorneyAnimation

var current_state: EmoteState = EmoteState.PRE

## Whether the image dialog is selecting a preanim or idle emote image.
var is_image_pre: bool = false

var button_image_type: ButtonImageType = ButtonImageType.BG

## Whether the currently selected button slot is the on or off state.
var is_button_image_on: bool = false

## ImageMagick utility reference, used for splitting animated frames.
var magick: Magick

#endregion

#region Onready Nodes
## The file dialog used to select the INI file.
@onready var file_dialog: FileDialog = %FileDialog
## The file dialog used to save the INI file.
## TODO: might be better to just re-use the same file dialog?
@onready var file_dialog_save: FileDialog = %FileDialogSave
## The FileDialog used to select an image.
## TODO: might be better to just re-use the same file dialog?
@onready var image_dialog: FileDialog = %ImageDialog
## The FileDialog used to select an image for an emote button.
## TODO: might be better to just re-use the same file dialog?
@onready var button_image_dialog: FileDialog = %ButtonImageDialog

## The confirmation dialog that pops up for things such as overwriting, etc.
@onready var confirmation_dialog: ConfirmationDialog = %ConfirmationDialog
## The dialog that only pops up if the program detects that the user doesn't
## have ImageMagick installed. If that's the case, give them the downloda link.
@onready var install_magick_dialog: AcceptDialog = %InstallMagickDialog

## The loading screen that appears when we have to wait on heavy operations,
## such as ImageMagick splitting up an animated format into frames, etc.
@onready var loading_screen: ColorRect = %LoadingScreen

## The label shown on the loading screen.
@onready var loading_label: Label = %LoadingLabel

## The split container for character and emote properties
@onready var left_split_container: VSplitContainer = %LeftSplitContainer

## The split container for the main view, button maker and emotes list
@onready var center_split_container: VSplitContainer = %CenterSplitContainer

#region Character Emotes
## The fold that contains the emotes of the character.
@onready var emotes_fold: FoldableContainer = %EmotesFold
## The list of emotes present on the current character.
@onready var emote_list: ItemList = %EmoteList
## The button to press to add a new blank emote to the emote list.
@onready var add_emote_button: Button = %AddEmoteButton
#endregion

#region Animation Controls
## The buttons that show up when an emote is a valid animation.
## Doesn't show up if the emote is static.
@onready var animation_buttons: AnimationButtons = %AnimationButtons
## The option button responsible for selecting the type of emote animation to display.
## The options are pre, idle, talk, post.
@onready var animation_option_button: OptionButton = %AnimationOptionButton

## The check button responsible if the preanimation should be looped
## or if it should progress to the idle animation when finished.
@onready var loop_pre_button: CheckButton = %LoopPreButton
#endregion

#region Character Options
## The fold that contains the options of the character, including
## save/load buttons etc.
@onready var character_fold: FoldableContainer = %CharacterFold

## The button to press to begin working on a new character.
@onready var new_button: Button = %NewButton
## The button to press to open a pre-existing INI file.
@onready var open_ini_button: Button = %OpenIniButton
## The button to press to save the current INI file.
@onready var save_ini_button: Button = %SaveIniButton

## The button to open a Godot .tscn scene file as a character
@onready var open_tscn_button: Button = %OpenTscnButton
## The button to save the current character as a Godot .tscn scene file
@onready var save_tscn_button: Button = %SaveTscnButton
## The tab container that contains Char.ini Options and Credits
@onready var tab_container: TabContainer = %TabContainer

## The current character's detected char_icon.png.
## TODO: Allow the user to create one directly from the program?
@onready var character_icon: TextureRect = %CharIcon
## The label showing the user the currently opened character folder.
@onready var char_folder_label: Label = %CharFolderLabel
## The label that shows a warning of a problem w/ the character
@onready var warning_label: Label = %WarningLabel

## The LineEdit responsible for the character name, not to be confused with
## the Showname. Character name is a legacy field for old-style iniswapping.
@onready var charname_edit: LineEdit = %CharnameEdit
## The character name to display in the dialog box and the ic logs,
## unless overridden with a custom showname by the user.
@onready var showname_edit: LineEdit = %ShownameEdit
## If this character will have a showname displayed by default, or if it should
## use a nameplate-less dialog box instead.
@onready var showname_check: CheckBox = %ShownameCheck
## Edits the character's default position on the background
@onready var side_edit: LineEdit = %SideEdit
## Edits the character's blip sounds when talking (formerly known as gender)
@onready var blips_edit: LineEdit = %BlipsEdit
## The character's default chat box to search for in the misc/ folder.
## Does nothing if the user's custom chatboxes are disabled.
@onready var chat_edit: LineEdit = %ChatEdit
## The character's custom effects to search for in the misc/ folder.
## Adds them to the bottom of the effects dropdown after the theme's effects.
@onready var effects_edit: LineEdit = %EffectsEdit
## The custom realization sound to use for this character.
@onready var realization_edit: LineEdit = %RealizationEdit
## This character's custom category, only relevant for the character list dropdown.
@onready var category_edit: LineEdit = %CategoryEdit
## The scaling option to use for this character when resized.
## Smooth is blurry, Pixel is pixelated.
@onready var scaling_option: OptionButton = %ScalingOption
#endregion

## The text edit responsible for modifying the credits.txt file
@onready var credits_text_edit: TextEdit = %CreditsTextEdit

#region Character Emote Properties
## The fold that contains the currently selected emote's porperties.
## Hidden when no emotes are selected.
@onready var emote_properties_fold: FoldableContainer = %EmotePropertiesFold
## Currently selected emote's index.
## When changed it moves the emote and rearranges the emote list.
@onready var number_spin_box: SpinBox = %NumberSpinBox
## When pressed, prompts the user if they want to delete the currently selected emote.
## Can hold "Shift" key to bypass the warning.
@onready var delete_emote_button: Button = %DeleteEmoteButton
## The emote's name that is displayed when hovered over by the user,
## or what shows in the emote dropdown
@onready var display_name_edit: LineEdit = %DisplayNameEdit
## The preanimation image path
@onready var preanim_edit: LineEdit = %PreanimEdit
## The idle/talk image path.
## AO prefixes (a) for idle, (b) for talk to find the relevant image.
## If neither is found, falls back to the path as-is.
@onready var emote_edit: LineEdit = %EmoteEdit
## The emote modifier to use for this emote.
## The options are the same as [enum Emote.EmoteMod]
@onready var modifier_option: OptionButton = %ModifierOption
## The desk modifier to use for this emote.
## The options are the same as [enum Emote.DeskMod]
@onready var deskmod_option: OptionButton = %DeskmodOption
## The name of the sound effect to use for this emote.
## If blank, no sound effect will be used.
@onready var sound_name_edit: LineEdit = %SoundNameEdit
## The time to delay the sound effect in ticks (60ms per tick)
@onready var sound_time_edit: SpinBox = %SoundTimeEdit
## If checked, the sound effect will be looped.
@onready var sound_loop_check: CheckBox = %SoundLoopCheck
## The button to set the preanimation image path to.
@onready var set_preanim_button: Button = %SetPreanimButton
## The button to set the emote image path to. Prefix is automatically trimmed.
@onready var set_emote_button: Button = %SetEmoteButton
#endregion

#region Button Maker
## The button to show/hide the [param button_maker].
## Also enables the [ButtonCropper].
@onready var button_maker_check_button: CheckButton = %ButtonMakerCheckButton
## The ButtonMaker panel that contains all the rest of the controls for
## making emote buttons.
@onready var button_maker: Control = %ButtonMaker
## Previewer of the current region as displayed in the associated [ButtonCropper]
## including background, forgeround and mask.
## Keep in mind the [param capture_button] render is rendered differently!
@onready var button_previewer: ButtonPreviewer = %ButtonPreviewer
## The pixel size to output the final button image in.
@onready var button_size_spin_box: SpinBox = %ButtonSizeSpinBox

## Takes a screenshot of the current region inside of the [ButtonCropper] and
## renders the currently selected button with the background, foreground and
## mask layers applied.
@onready var capture_button: Button = %CaptureButton

## Load the background image to use for the screencap from the [param  capture_button]
@onready var load_bg_button: Button = %LoadBGButton
## Clear the background image to use for the screencap from the [param  capture_button]
@onready var clear_bg_button: Button = %ClearBGButton
## Load the foreground image to use for the screencap from the [param  capture_button]
@onready var load_fg_button: Button = %LoadFGButton
## Clear the foreground image to use for the screencap from the [param  capture_button]
@onready var clear_fg_button: Button = %ClearFGButton
## Load the mask image to use for the screencap from the [param  capture_button]
@onready var load_mask_button: Button = %LoadMaskButton
## Clear the mask image to use for the screencap from the [param  capture_button]
@onready var clear_mask_button: Button = %ClearMaskButton

#region Emote Off Button
## The panel that contains the off button controls
@onready var off_button_panel: PanelContainer = %OffButtonPanel
## The preview of the off button image for the Emote
@onready var off_button_icon: TextureRect = %OffButtonIcon
## Takes a screenshot of the current region inside of the [ButtonCropper] and
## renders the off button with background, foreground and mask layers applied.
@onready var off_photo_button: Button = %OffPhotoButton
## Load a specific image as the off button
@onready var off_load_button: Button = %OffLoadButton
#endregion

#region Emote On Button
## The panel that contains the on button controls
@onready var on_button_panel: PanelContainer = %OnButtonPanel
## The preview of the on button image for the Emote
@onready var on_button_icon: TextureRect = %OnButtonIcon
## Takes a screenshot of the current region inside of the [ButtonCropper] and
## renders the on button with background, foreground and mask layers applied.
@onready var on_photo_button: Button = %OnPhotoButton
## Load a specific image as the on button
@onready var on_load_button: Button = %OnLoadButton
#endregion
#endregion
## The box container that has the Emotes navigator
@onready var emotes_box_container: VBoxContainer = %EmotesBoxContainer

## The button that appears when the emote list is empty.
## When pressed, it scans the folder where the current char.ini is,
## detects valid animated images and creates emotes out of them.
@onready var scan_emotes_button: Button = %ScanEmotesButton

## The button to open the current character folder in the user's file system
@onready var open_current_folder_button: Button = %OpenCurrentFolderButton

## The world containing the character sprite
@onready var world: Node2D = %World
#endregion

#region Built-in Methods

func _ready() -> void:
	new_button.pressed.connect(_on_new_button_pressed)
	open_ini_button.pressed.connect(_on_open_ini_button_pressed)
	save_ini_button.pressed.connect(_on_save_ini_button_pressed)

	open_tscn_button.pressed.connect(_on_open_tscn_button_pressed)
	save_tscn_button.pressed.connect(_on_save_tscn_button_pressed)

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
	showname_check.toggled.connect(_on_char_need_showname_changed)
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
	display_name_edit.text_changed.connect(_on_emote_display_name_changed)
	preanim_edit.text_submitted.connect(_on_preanim_edit_changed)
	preanim_edit.focus_exited.connect(_on_preanim_lost_focus)
	emote_edit.text_submitted.connect(_on_emote_edit_changed)
	emote_edit.focus_exited.connect(_on_emote_lost_focus)
	modifier_option.item_selected.connect(_on_emote_mod_changed)
	deskmod_option.item_selected.connect(_on_emote_deskmod_changed)
	sound_name_edit.text_changed.connect(_on_emote_sound_changed)
	sound_time_edit.value_changed.connect(_on_emote_sound_time_changed)
	sound_loop_check.toggled.connect(_on_emote_sound_loop_changed)
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
	emote_properties_fold.folding_changed.connect(_on_emote_properties_folding_changed)

	button_maker_check_button.toggled.connect(_on_button_maker_toggled)

	capture_button.pressed.connect(_on_capture_pressed)

	scan_emotes_button.pressed.connect(_on_scan_emotes_button_pressed)

	open_current_folder_button.pressed.connect(_on_open_current_folder_button_pressed)

	magick = Magick.new()
	var magick_real: bool = magick.test_magick()
	if not magick_real:
		install_magick_dialog.popup_centered()
	
	emotes_box_container.hide()
	tab_container.hide()
	open_current_folder_button.disabled = true
	save_ini_button.disabled = true
	save_tscn_button.disabled = true
	button_maker_check_button.disabled = true


# func _notification(what):
# 	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
# 		print("hello there")

#endregion

#region Character File Operations

## Resets the editor state and creates a new blank character.
func _on_new_button_pressed() -> void:
	clear_world()
	current_character = Character.new()
	current_character.ini_path = ""
	
	load_character({ })
	regenerate_buttons()
	character_icon.texture = CHAR_ICON_BORDER
	char_folder_label.text = "Unsaved Character"
	char_folder_label.tooltip_text = "Make sure to Save this character!"
	
	warning_label.show()
	warning_label.text = "Make sure to Save this character!"

	emotes_box_container.show()
	tab_container.show()
	open_current_folder_button.disabled = true
	save_ini_button.disabled = false
	save_tscn_button.disabled = false
	button_maker_check_button.disabled = false


## Opens the file dialog to select a character INI file.
func _on_open_ini_button_pressed() -> void:
	file_dialog.popup_centered()


## Loads a character from a selected INI file path, populates the UI.
func _on_file_selected(path: String) -> void:
	clear_world()
	current_character = Character.new()
	current_character.ini_path = path
	warning_label.hide()
	emotes_box_container.show()
	tab_container.show()
	open_current_folder_button.disabled = false
	save_ini_button.disabled = false
	save_tscn_button.disabled = false
	button_maker_check_button.disabled = false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	load_character(BasicIni.parse(file.get_as_text()))
	animation_option_button.disabled = false
	regenerate_buttons()
	var char_folder: String = current_character.get_folder()
	load_char_icon_from_filepath(char_folder + "/char_icon.png")
	char_folder_label.text = char_folder.get_basename().get_file()
	char_folder_label.tooltip_text = char_folder
	load_credits_file()


## Reads the character's credits.txt into the credits editor (case-insensitive for Linux).
func load_credits_file() -> void:
	if not current_character:
		return
	var credits_file: FileAccess
	var char_folder: String = current_character.get_folder()
	for file: String in DirAccess.get_files_at(char_folder):
		if file.to_lower() == "credits.txt":
			credits_file = FileAccess.open(char_folder + "/" + file, FileAccess.READ)
			break
	credits_text_edit.clear()
	if credits_file:
		credits_text_edit.text = credits_file.get_as_text()


## Writes the credits editor content back to credits.txt (case-insensitive for Linux).
func save_credits_file() -> void:
	if not current_character:
		return
	var char_folder: String = current_character.get_folder()
	for file: String in DirAccess.get_files_at(char_folder):
		if file.to_lower() == "credits.txt":
			DirAccess.remove_absolute(char_folder + "/" + file)
	var credits_file: FileAccess = FileAccess.open(char_folder + "/credits.txt", FileAccess.WRITE)
	credits_file.store_string(credits_text_edit.text)


## Loads a character icon PNG from disk and sets it on the character icon texture rect.
func load_char_icon_from_filepath(icon_path: String) -> void:
	var image: Image = Image.load_from_file(icon_path)
	var image_texture: ImageTexture = ImageTexture.create_from_image(image)
	character_icon.texture = image_texture


func _on_char_icon_file_selected(file_path: String) -> void:
	load_char_icon_from_filepath(file_path)


## Opens the save file dialog for the character's INI path.
func _on_save_ini_button_pressed() -> void:
	file_dialog_save.filters = ["*.ini;Char.ini file"]
	file_dialog_save.current_dir = current_character.get_folder()
	file_dialog_save.title = "Save Ini"
	file_dialog_save.popup_centered()


## Load a tscn file
func _on_open_tscn_button_pressed() -> void:
	print("Lol")


## Save a tscn file
func _on_save_tscn_button_pressed() -> void:
	file_dialog_save.filters = ["*.tscn;.tscn file"]
	file_dialog_save.current_dir = current_character.get_folder()
	file_dialog_save.title = "Save Tscn"
	file_dialog_save.popup_centered()


## Writes the INI file and saves button images. Prompts for confirmation if the
## emotions folder already exists.
func _on_save_file_selected(path: String) -> void:
	if file_dialog_save.title == "Save Tscn":
		for idx: int in current_character.emotes.size():
			await _on_emote_selected(idx)
		var save_dir: String = path.get_base_dir()
		for child: Node in world.get_children():
			var anim_node: AttorneyAnimation = child as AttorneyAnimation
			if not anim_node:
				continue
			DirAccess.make_dir_recursive_absolute(save_dir)
			var lib: AnimationLibrary = anim_node.animation_player.get_animation_library("")
			if not lib:
				continue
			for anim_name: StringName in lib.get_animation_list():
				var animation: Animation = lib.get_animation(anim_name)
				var anim_key: String = String(anim_name).replace("|", "/")
				for track_idx: int in animation.get_track_count():
					var key_count: int = animation.track_get_key_count(track_idx)
					for key_idx: int in key_count:
						var tex: ImageTexture = animation.track_get_key_value(track_idx, key_idx) as ImageTexture
						if not tex:
							continue
						var frame_path: String = save_dir + "/frames/" + anim_key + "/" + str(key_idx + 1) + ".webp"
						DirAccess.make_dir_recursive_absolute(frame_path.get_base_dir())
						if tex.get_image().save_webp(frame_path) != OK:
							push_error("Failed to save frame texture: ", frame_path)
							continue
						tex.resource_path = "res://" + save_dir.get_file() + "/" + frame_path.trim_prefix(save_dir + "/")
						print(tex.resource_path)
		var packed_scene: PackedScene = PackedScene.new()
		for node: Node in world.find_children("*"):
			node.owner = world
		var result: Error = packed_scene.pack(world)
		if result != OK:
			push_error("An error occurred while packing the scene.")
			return
		var error: Error = ResourceSaver.save(packed_scene, path)
		if error != OK:
			push_error("An error occurred while saving the scene to disk.")
			return
	else:
		var ini_string: String = BasicIni.make_char_ini(current_character.save_data())
		var save_file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		save_file.store_string(ini_string)
	save_credits_file()
	current_character.ini_path = path
	warning_label.hide()
	emotes_box_container.show()
	tab_container.show()
	open_current_folder_button.disabled = false
	save_ini_button.disabled = false
	save_tscn_button.disabled = false
	button_maker_check_button.disabled = false
	var save_folder: String = path.get_base_dir()
	load_char_icon_from_filepath(save_folder + "/char_icon.png")
	char_folder_label.text = save_folder.get_basename().get_file()
	char_folder_label.tooltip_text = save_folder
	save_buttons_prompt(save_folder)


## Backs up and overwrites the emotions folder when the user confirms.
func _on_emotions_overwrite_confirmed(save_folder: String) -> void:
	if confirmation_dialog.confirmed.is_connected(_on_emotions_overwrite_confirmed):
		confirmation_dialog.confirmed.disconnect(_on_emotions_overwrite_confirmed)
	if confirmation_dialog.canceled.is_connected(_on_emotions_overwrite_cancelled):
		confirmation_dialog.canceled.disconnect(_on_emotions_overwrite_cancelled)
	save_buttons(save_folder)


## Cleans up confirmation dialog signal connections when overwrite is cancelled.
func _on_emotions_overwrite_cancelled() -> void:
	if confirmation_dialog.confirmed.is_connected(_on_emotions_overwrite_confirmed):
		confirmation_dialog.confirmed.disconnect(_on_emotions_overwrite_confirmed)
	if confirmation_dialog.canceled.is_connected(_on_emotions_overwrite_cancelled):
		confirmation_dialog.canceled.disconnect(_on_emotions_overwrite_cancelled)


## Saves the off/on button PNG images for all emotes into the emotions folder,
## backing up any existing files to _old_emotions.
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
		var button_path: String = emotions_folder + "button" + str(idx + 1)
		if emote.image_off:
			emote.image_off.get_image().save_png(button_path + "_off.png")
		if emote.image_on:
			emote.image_on.get_image().save_png(button_path + "_on.png")

## Prompts for confirmation if the emotions folder already exists, otherwise
## calls save_buttons()
func save_buttons_prompt(save_folder: String) -> void:
	var emotions_folder: String = save_folder + "/emotions/"
	if DirAccess.dir_exists_absolute(emotions_folder):
		confirmation_dialog.title = "Overwrite Buttons?"
		confirmation_dialog.dialog_text = """
Warning: your  char.ini was saved, however,
/emotions/ folder already exists and will be overwritten.
If you press "Accept", an /_old_emotions/ folder will be created as backup.
If /_old_emotions/ already exists, all the files inside of it will also be overwritten!
		"""
		confirmation_dialog.ok_button_text = "Accept"
		confirmation_dialog.popup_centered()
		confirmation_dialog.confirmed.connect(
			_on_emotions_overwrite_confirmed.bind(save_folder),
			CONNECT_ONE_SHOT,
		)
		confirmation_dialog.canceled.connect(
			_on_emotions_overwrite_cancelled,
			CONNECT_ONE_SHOT,
		)
		return
	save_buttons(save_folder)


## Opens the character's folder in the system file manager.
func _on_open_current_folder_button_pressed() -> void:
	if current_character.ini_path.is_empty():
		return
	OS.shell_show_in_file_manager(current_character.ini_path)

#endregion

#region Character Properties

## Updates the character's display name from the UI.
func _on_char_name_changed(new_text: String) -> void:
	current_character.char_name = new_text


## Updates the character's showname from the UI.
func _on_char_showname_changed(new_text: String) -> void:
	current_character.showname = new_text


## Updates whether the character needs a showname override.
func _on_char_need_showname_changed(toggled_on: bool) -> void:
	current_character.needs_showname = toggled_on


## Updates the character side (prosecution/defense) from the UI.
func _on_char_side_changed(new_text: String) -> void:
	current_character.side = new_text


## Updates the blip sound override from the UI.
func _on_char_blips_changed(new_text: String) -> void:
	current_character.blips = new_text


## Updates the character chat bubble style from the UI.
func _on_char_chat_changed(new_text: String) -> void:
	current_character.chat = new_text


## Updates the effects (e.g. speedlines) from the UI.
func _on_char_effects_changed(new_text: String) -> void:
	current_character.effects = new_text


## Updates the realization overlay from the UI.
func _on_char_realization_changed(new_text: String) -> void:
	current_character.realization = new_text


## Updates the character category from the UI.
func _on_char_category_changed(new_text: String) -> void:
	current_character.category = new_text


## Updates the character scaling mode (pixel vs. smooth) from the UI.
func _on_char_scaling_changed(index: int) -> void:
	current_character.scaling = scaling_option.get_item_text(index)

#endregion

#region Emote Management

## Adds a new blank emote to the character and updates the UI.
func _on_add_emote_pressed() -> void:
	if not current_character:
		return
	var emote: Emote = Emote.new("Blank")
	current_character.emotes.append(emote)
	number_spin_box.set_block_signals(true)
	number_spin_box.max_value = current_character.emotes.size()
	number_spin_box.set_block_signals(false)
	set_emote_button_images(
		emote,
		current_character.get_folder() + "/emotions/",
		current_character.emotes.size(),
	)
	add_emote_list_button(emote)


## Reorders the emote in the list to match the spin box value when the user changes it.
func _on_emote_number_changed(value: float) -> void:
	var index_from: int = current_emote_number
	var index_to: int = int(value) - 1
	current_character.emotes.insert(index_to, current_character.emotes.pop_at(index_from))
	emote_list.move_item(index_from, index_to)
	current_emote_number = index_to


## Prompts for confirmation before deleting an emote. Hold Shift to skip the prompt.
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
		CONNECT_ONE_SHOT,
	)
	confirmation_dialog.canceled.connect(
		_on_delete_emote_canceled,
		CONNECT_ONE_SHOT,
	)


## Deletes the current emote after the user confirms in the confirmation dialog.
func _on_delete_emote_confirmed() -> void:
	if confirmation_dialog.confirmed.is_connected(_on_delete_emote_confirmed):
		confirmation_dialog.confirmed.disconnect(_on_delete_emote_confirmed)
	if confirmation_dialog.canceled.is_connected(_on_delete_emote_canceled):
		confirmation_dialog.canceled.disconnect(_on_delete_emote_canceled)
	delete_emote(current_emote_number)


## Cleans up confirmation dialog signal connections when deletion is cancelled.
func _on_delete_emote_canceled() -> void:
	if confirmation_dialog.confirmed.is_connected(_on_delete_emote_confirmed):
		confirmation_dialog.confirmed.disconnect(_on_delete_emote_confirmed)
	if confirmation_dialog.canceled.is_connected(_on_delete_emote_canceled):
		confirmation_dialog.canceled.disconnect(_on_delete_emote_canceled)


## Removes an emote by index and updates the UI list and spin box bounds.
func delete_emote(idx: int) -> void:
	current_character.emotes.remove_at(idx)
	number_spin_box.set_block_signals(true)
	number_spin_box.max_value = current_character.emotes.size()
	number_spin_box.set_block_signals(false)
	emote_list.remove_item(idx)
	_on_emote_selected.call_deferred(clampi(0, idx - 1, current_character.emotes.size()))


## Rebuilds the emote list UI buttons from the current character data.
func regenerate_buttons(read_emote_folder: bool = true) -> void:
	emote_list.clear()
	for i: int in current_character.emotes.size():
		var emote: Emote = current_character.emotes[i]
		if read_emote_folder:
			set_emote_button_images(emote, current_character.get_folder() + "/emotions/", i)
		add_emote_list_button(emote)
	scan_emotes_button.set_visible(current_character.emotes.is_empty())


## Adds a single emote entry to the emote list with its off-state icon and tooltip.
func add_emote_list_button(emote: Emote) -> void:
	var icon: Texture2D = emote.image_off
	if icon == null:
		icon = BUTTON_PLACEHOLDER
	var at: int = emote_list.add_item(emote.display_name, icon)
	emote_list.set_item_metadata(at, emote)
	emote_list.set_item_tooltip(
		at,
		"%s\n%s: %s, %s" % [emote.display_name, at + 1, emote.pre, emote.idle],
	)


## Loads off/on button PNG images from disk for the emote at the given index.
func set_emote_button_images(emote: Emote, folder_path: String, idx: int) -> void:
	var button_path: String = folder_path + "button" + str(idx + 1)
	var button_off_path: String = button_path + "_off.png"
	var button_on_path: String = button_path + "_on.png"
	if FileAccess.file_exists(button_off_path):
		emote.image_off = ImageTexture.create_from_image(Image.load_from_file(button_off_path))
	if FileAccess.file_exists(button_on_path):
		emote.image_on = ImageTexture.create_from_image(Image.load_from_file(button_on_path))


## Selects an emote by index and updates all UI fields and previews.
func _on_emote_selected(idx: int) -> void:
	if idx < 0 or idx >= current_character.emotes.size():
		emote_properties_fold.hide()
		scan_emotes_button.set_visible(current_character.emotes.is_empty())
		return
	emote_properties_fold.show()
	var previous_emote_number: int = current_emote_number
	current_emote_number = idx
	emote_list.select(current_emote_number)
	number_spin_box.set_block_signals(true)
	number_spin_box.value = idx + 1
	number_spin_box.set_block_signals(false)
	var emote: Emote = current_character.emotes[idx]
	display_name_edit.text = emote.display_name
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
			emote_list.set_item_icon(previous_emote_number, previous_emote.image_off as Texture2D)
	var icon: Texture2D = emote.image_off
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
	await load_emote_images(emote, current_character)
	if emote.emote_mod == Emote.EmoteMod.PREANIM:
		_on_anim_state_selected(EmoteState.PRE)
	else:
		_on_anim_state_selected(EmoteState.IDLE)


## Loads all the associated images with the Emote with an await and a loading screen.
func load_emote_images(emote: Emote, character: Character) -> void:
	loading_screen.show()
	var pre_image_path: String = search_valid_emote(
		character.get_folder(),
		emote.pre,
		"pre",
	)
	var idle_image_path: String = search_valid_emote(
		character.get_folder(),
		emote.idle,
		"idle",
	)
	var talk_image_path: String = search_valid_emote(
		character.get_folder(),
		emote.idle,
		"talk",
	)
	var post_image_path: String = search_valid_emote(
		character.get_folder(),
		emote.idle,
		"post",
	)
	animation_option_button.disabled = false
	animation_option_button.set_item_disabled(0, true)
	animation_option_button.set_item_disabled(1, true)
	animation_option_button.set_item_disabled(2, true)
	animation_option_button.set_item_disabled(3, true)
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
#endregion

#region Emote Properties

## Opens the image file dialog for selecting a preanim image.
func _on_set_preanim_button_pressed() -> void:
	is_image_pre = true
	image_dialog.current_dir = current_character.get_folder()
	image_dialog.popup_centered()


## Opens the image file dialog for selecting an idle emote image.
func _on_set_emote_button_pressed() -> void:
	is_image_pre = false
	image_dialog.current_dir = current_character.get_folder()
	image_dialog.popup_centered()


## Handles direct text entry for the preanim path.
func _on_preanim_edit_changed(new_text: String) -> void:
	is_image_pre = true
	_on_image_selected(new_text)


## Commits the preanim path when the preanim edit loses focus.
func _on_preanim_lost_focus() -> void:
	if preanim_edit.text == current_character.emotes[current_emote_number].pre:
		return
	is_image_pre = true
	_on_image_selected(preanim_edit.text)


## Handles direct text entry for the idle emote path.
func _on_emote_edit_changed(new_text: String) -> void:
	is_image_pre = false
	_on_image_selected(new_text)


## Commits the idle emote path when the emote edit loses focus.
func _on_emote_lost_focus() -> void:
	if emote_edit.text == current_character.emotes[current_emote_number].idle:
		return
	is_image_pre = false
	_on_image_selected(emote_edit.text)


## Sets an image path on the current emote (preanim or idle depending on is_image_pre).
func _on_image_selected(path: String) -> void:
	if is_image_pre:
		preanim_edit.text = get_emote_path(path, false)
		current_character.emotes[current_emote_number].pre = preanim_edit.text
	else:
		emote_edit.text = get_emote_path(path)
		current_character.emotes[current_emote_number].idle = emote_edit.text
	_on_emote_selected.call_deferred(current_emote_number)


## Converts a full file path to a relative emote path, stripping (a)/(b)/(c) prefixes.
func get_emote_path(file_path: String, trim_prefix: bool = true) -> String:
	var result: String = file_path.get_basename().trim_prefix(
		current_character.get_folder() + "/",
	)
	if trim_prefix:
		result = result.trim_prefix("(a)").trim_prefix("(b)").trim_prefix("(c)")
	return result


## Updates the emote display name from the UI.
func _on_emote_display_name_changed(new_text: String) -> void:
	current_character.emotes[current_emote_number].display_name = new_text
	emote_list.set_item_text(current_emote_number, new_text)


## Updates the emote modifier (e.g. preanim) from the UI.
func _on_emote_mod_changed(index: int) -> void:
	var emote_mod: Emote.EmoteMod = modifier_option.get_item_id(index) as Emote.EmoteMod
	current_character.emotes[current_emote_number].emote_mod = emote_mod


## Updates the desk modifier from the UI.
func _on_emote_deskmod_changed(index: int) -> void:
	var desk_mod: Emote.DeskMod = deskmod_option.get_item_id(index) as Emote.DeskMod
	current_character.emotes[current_emote_number].desk_mod = desk_mod


## Updates the emote's SFX name from the UI.
func _on_emote_sound_changed(new_text: String) -> void:
	current_character.emotes[current_emote_number].sound_name = new_text


## Updates the emote's SFX delay from the UI.
func _on_emote_sound_time_changed(value: float) -> void:
	current_character.emotes[current_emote_number].sound_time = int(value)


## Updates whether the emote's SFX loops from the UI.
func _on_emote_sound_loop_changed(toggled_on: bool) -> void:
	current_character.emotes[current_emote_number].sound_loop = toggled_on


## Toggles the button maker panel visibility.
func _on_button_maker_toggled(toggled_on: bool) -> void:
	button_maker.visible = toggled_on
	button_maker_toggled.emit(toggled_on)


## Collapses the center split container when the emote list fold is toggled.
func _on_emotes_folding_changed(is_folded: bool) -> void:
	center_split_container.collapsed = is_folded


## Adjusts the character fold container sizing and collapses the left panel.
func _on_character_folding_changed(_is_folded: bool) -> void:
	if character_fold.folded:
		character_fold.size_flags_vertical = Control.SIZE_FILL
	else:
		character_fold.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_split_container.collapsed = character_fold.folded or emote_properties_fold.folded


## Collapses the left panel when the emote properties fold is toggled.
func _on_emote_properties_folding_changed(_is_folded: bool) -> void:
	left_split_container.collapsed = character_fold.folded or emote_properties_fold.folded

#endregion

#region Image Loading & Preview

## Loads an image file into the world view, handling both static and animated formats.
func load_image_file(image_path: String) -> void:
	var local_path: String = image_path.trim_prefix(
		current_character.get_folder() + "/",
	).get_basename()
	var node_name: String = local_path.replace("/", "|")
	if is_instance_valid(world.get_node_or_null(node_name)):
		return
	if current_anim and current_anim.animation_player.has_animation(node_name):
		return
	var file_extension: String = image_path.get_extension()
	if file_extension in ANIMATED_EXTENSIONS:
		await handle_animated_file(image_path)
	if file_extension in STATIC_EXTENSIONS:
		handle_static_file(image_path)


## Extracts frames from an animated file (webp/apng/gif) and creates an AttorneyAnimation.
func handle_animated_file(image_path: String) -> void:
	var directory: String = image_path.get_base_dir()
	var base_name: String = image_path.get_file().get_basename()
	var local_path: String = image_path.trim_prefix(
		current_character.get_folder() + "/",
	).get_basename()
	loading_label.text = "Loading %s...\nObtaining frame data..." % local_path
	var frame_data: Array[Dictionary] = await magick.get_threaded_frame_data(image_path)
	var char_name: String = directory.get_file()
	var frames_folder: String = ProjectSettings.globalize_path(
		"user://frame_cache/%s/%s/" % [char_name, base_name],
	)
	loading_label.text = "Loading %s...\nSplitting frames..." % local_path
	if not FileAccess.file_exists(frames_folder):
		await magick.get_threaded_split_frames(image_path, frames_folder)
	loading_label.text = "Loading %s...\nCreating AttorneyAnimation..." % local_path
	if not current_anim:
		current_anim = AttorneyAnimation.new()
		current_anim.name = char_name # local_path.replace("/", "|")
		world.add_child(current_anim)
		current_anim.owner = world
		# assumes animation player exists
		current_anim.animation_player.animation_finished.connect(
			_on_pre_finished
		)
	current_anim.add_frames_from_folder(frames_folder)
	current_anim.initialize_from_frame_data(local_path, frame_data)
	if scaling_option.selected == 0:
		world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	elif scaling_option.selected == 1:
		world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Loads a static PNG image as a Sprite2D in the world view.
## TODO: static image file should still be treated as a single-frame AttorneyAnimation
func handle_static_file(image_path: String) -> void:
	var image: Image = Image.load_from_file(image_path)
	var image_texture: ImageTexture = ImageTexture.create_from_image(image)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = image_texture
	sprite.set_texture(image_texture)
	var local_path: String = image_path.trim_prefix(
		current_character.get_folder() + "/",
	).get_basename()
	sprite.name = local_path.replace("/", "|")
	sprite.owner = world
	world.add_child(sprite)


## Removes all child nodes from the world viewport and resets animation controls.
func clear_world() -> void:
	animation_buttons.set_animation_player(null)
	loop_pre_button.disabled = true
	animation_option_button.disabled = true
	for child: Node in world.get_children():
		child.queue_free()


## Updates the world viewport texture filter when the scaling option changes.
func _on_scaling_selected(index: int) -> void:
	if index == 0:
		world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	elif index == 1:
		world.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

#endregion

#region Animation Preview

## Switches the preview to the selected animation state (pre/idle/talk/post).
func _on_anim_state_selected(index: int) -> void:
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
	animation_buttons.set_animation_player(null)
	for child: Node2D in world.get_children():
		child.hide()
	emote_name = emote_name.replace("/", "|")
	var find_emote: Node2D = world.get_node_or_null(prefix + emote_name)
	if not find_emote:
		find_emote = world.get_node_or_null(emote_name)
	if not find_emote:
		if not current_anim:
			return
		var animation_player: AnimationPlayer = current_anim.animation_player
		animation_player.stop()
		current_anim.show()
		if animation_player.has_animation(prefix + emote_name):
			animation_player.play(prefix + emote_name)
		elif animation_player.has_animation(emote_name):
			animation_player.play(emote_name)
		else:
			return
		loop_pre_button.disabled = false
		var animation: Animation = \
			animation_player.get_animation(
				animation_player.current_animation
			)
		if current_state == EmoteState.PRE:
			animation_buttons.show()
			if loop_pre_button.button_pressed:
				animation.loop_mode = Animation.LOOP_LINEAR
			else:
				animation.loop_mode = Animation.LOOP_NONE
		else:
			if current_anim.animation_player.current_animation != "" \
					and snapped(current_anim.animation_player.current_animation_length, 0.001) > 0.001:
				animation.loop_mode = Animation.LOOP_LINEAR
				animation_buttons.show()
			else:
				animation.loop_mode = Animation.LOOP_NONE
				animation_buttons.hide()
		animation_buttons.set_animation_player(animation_player)
	elif not (find_emote is AttorneyAnimation):
		current_anim.hide()
		find_emote.show()
		animation_buttons.hide()


## When the preanim finishes playing, automatically transitions to the idle state.
func _on_pre_finished(_anim_name: StringName) -> void:
	if current_state != EmoteState.PRE:
		return
	# wait a frame so we don't create a frame where nothing is shown
	await get_tree().process_frame
	_on_anim_state_selected(EmoteState.IDLE)


## Toggles looping for the preanim animation when the pre state is selected.
func _on_loop_pre_button_toggled(toggled_on: bool) -> void:
	if not current_anim:
		return
	# preanim is NOT selected
	if animation_option_button.selected != 0:
		return
	var animation: Animation = \
		current_anim.animation_player.get_animation(
			current_anim.animation_player.current_animation
		)
	if toggled_on:
		animation.loop_mode = Animation.LOOP_LINEAR
	else:
		animation.loop_mode = Animation.LOOP_NONE

#endregion

#region Button Maker

## Applies the selected image to the button previewer (BG, FG, or mask layer).
func _on_button_image_file_selected(path: String) -> void:
	var image: Image = Image.load_from_file(path)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	match button_image_type:
		ButtonImageType.BG:
			button_previewer.button_bg.texture = texture
		ButtonImageType.FG:
			button_previewer.button_fg.texture = texture
		ButtonImageType.MASK:
			button_previewer.button_mask.texture = texture


## Opens the file dialog to load a background image for the button previewer.
func _on_load_bg_button_pressed() -> void:
	button_image_type = ButtonImageType.BG
	button_image_dialog.current_dir = current_character.get_folder()
	button_image_dialog.popup_centered()


## Clears the background image from the button previewer.
func _on_clear_bg_button_pressed() -> void:
	button_previewer.button_bg.texture = null


## Opens the file dialog to load a foreground image for the button previewer.
func _on_load_fg_button_pressed() -> void:
	button_image_type = ButtonImageType.FG
	button_image_dialog.current_dir = current_character.get_folder()
	button_image_dialog.popup_centered()


## Clears the foreground image from the button previewer.
func _on_clear_fg_button_pressed() -> void:
	button_previewer.button_fg.texture = null


## Opens the file dialog to load a mask image for the button previewer.
func _on_load_mask_button_pressed() -> void:
	button_image_type = ButtonImageType.MASK
	button_image_dialog.current_dir = current_character.get_folder()
	button_image_dialog.popup_centered()


## Clears the mask image from the button previewer.
func _on_clear_mask_button_pressed() -> void:
	button_previewer.button_mask.texture = null


## Selects the off-state button slot and updates the visual focus indicator.
func _on_off_photo_button_pressed() -> void:
	is_button_image_on = false
	off_button_panel.add_theme_stylebox_override(&"panel", PANEL_FOCUS)
	on_button_panel.add_theme_stylebox_override(&"panel", PANEL_NO_FOCUS)


## Selects the on-state button slot and updates the visual focus indicator.
func _on_on_photo_button_pressed() -> void:
	is_button_image_on = true
	off_button_panel.add_theme_stylebox_override(&"panel", PANEL_NO_FOCUS)
	on_button_panel.add_theme_stylebox_override(&"panel", PANEL_FOCUS)


## Captures the current button preview as an image, composites BG/FG/mask layers,
## and saves the result as the selected emote's off or on button texture.
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
		var fg_image: Image = button_previewer.button_fg.texture.get_image()
		# Ensure all images have alpha channels
		if fg_image.get_format() != Image.FORMAT_RGBA8:
			fg_image.convert(Image.FORMAT_RGBA8)
		if fg_image.get_size().x != button_size:
			fg_image.resize(button_size, button_size, Image.INTERPOLATE_BILINEAR)
		image.blend_rect(
			fg_image,
			Rect2i(Vector2i(0, 0), screencap.get_size()),
			Vector2i(0, 0),
		)

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
		for y: int in range(image.get_height()):
			for x: int in range(image.get_width()):
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
	_on_emote_selected.call_deferred(current_emote_number)
	button_previewer.sub_viewport.set_canvas_cull_mask_bit(1, true)
	button_previewer.button_mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	button_previewer.button_mask.self_modulate = Color.WHITE

#endregion

#region Folder Scanning

## Scans the character folder for emote image files and auto-creates emote entries.
func _on_scan_emotes_button_pressed() -> void:
	if not current_character:
		return
	var ignored_directories: PackedStringArray = [
		"emotions",
		"_old_emotions",
		"custom_objections",
	]
	var current_folder: String = current_character.get_folder()
	var found_emotes: PackedStringArray = scan_folder(current_folder, "")
	for folder: String in DirAccess.get_directories_at(current_folder):
		if folder.to_lower() in ignored_directories:
			continue
		found_emotes.append_array(scan_folder(current_folder + "/" + folder, current_folder))

	var pre_dict: Dictionary[String, bool] = { }
	for emote: String in found_emotes:
		print(emote)
		if emote.begins_with("(b)") or emote.begins_with("(c)"):
			continue
		if emote.begins_with("(a)"):
			var idle_emote: String = emote.right(-3)
			if pre_dict.has(idle_emote):
				pre_dict[idle_emote] = true
			else:
				pre_dict[idle_emote] = false
			continue
		if not pre_dict.has(emote):
			pre_dict[emote] = false
		else:
			pre_dict[emote] = true

	for key: String in pre_dict:
		var is_pre: bool = pre_dict[key]
		var emote: Emote = Emote.new(key.get_file().capitalize())
		emote.idle = key
		if is_pre:
			emote.pre = key
			emote.emote_mod = Emote.EmoteMod.PREANIM
		else:
			emote.pre = "-"
			emote.emote_mod = Emote.EmoteMod.IDLE
		current_character.emotes.append(emote)
	regenerate_buttons(false)
	number_spin_box.set_block_signals(true)
	number_spin_box.max_value = current_character.emotes.size()
	number_spin_box.set_block_signals(false)


## Recursively scans a folder for supported emote image files, returning relative paths.
func scan_folder(folder_path: String, base_folder: String = "") -> PackedStringArray:
	var ignored_filenames: PackedStringArray = [
		"char_icon",
		"custom",
		"holdit_bubble",
		"objection_bubble",
		"takethat_bubble",
		"defense_speedlines",
		"prosecution_speedlines",
	]
	var emote_files: PackedStringArray
	var local_folder_path: String = ""
	if not base_folder.is_empty():
		local_folder_path = folder_path.get_basename().trim_prefix(base_folder + "/") + "/"
	for file: String in DirAccess.get_files_at(folder_path):
		if file.get_basename().to_lower() in ignored_filenames:
			continue
		if file.get_extension() in SUPPORTED_EXTENSIONS:
			emote_files.append(local_folder_path + file.get_basename())
	return emote_files

#endregion

#region Utilities

## Searches the character folder for an emote file matching the given name and
## animation state (pre/idle/talk/post). Returns the first valid path found.
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
		try_path = "%s/%s.%s" % [char_folder, emote_name, ext]
		if FileAccess.file_exists(try_path):
			return try_path
	return ""


## Populates the UI from parsed character INI data.
func load_character(parsed_data: Dictionary[String, Dictionary]) -> void:
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
	# for some reason the "select" function does not emit signal
	scaling_option.item_selected.emit(scaling_option.selected)
	number_spin_box.set_block_signals(true)
	number_spin_box.max_value = current_character.emotes.size()
	number_spin_box.set_block_signals(false)
	# Don't select any emote
	_on_emote_selected.call_deferred(-1)

#endregion
