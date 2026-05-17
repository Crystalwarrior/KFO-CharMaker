extends Node


@onready var button_cropper: ReferenceRect = %ButtonCropper
@onready var char_converter: Control = %CharConverter

func _ready() -> void:
	get_tree().root.set_canvas_cull_mask_bit(1, false)
	char_converter.button_previewer.sub_viewport.world_2d = get_tree().root.world_2d
	char_converter.button_previewer.preview_target = button_cropper.button_crop_zone
	
	char_converter.button_maker_toggled.connect(_on_button_maker_toggled)


func _on_button_maker_toggled(toggled_on: bool) -> void:
	button_cropper.visible = toggled_on


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
