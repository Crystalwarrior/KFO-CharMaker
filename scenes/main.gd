extends Node


@onready var button_cropper: ReferenceRect = %ButtonCropper
@onready var center_ref: ColorRect = %CenterRef
@onready var char_converter: Control = %CharConverter

func _ready() -> void:
	get_tree().root.set_canvas_cull_mask_bit(1, false)
	char_converter.button_previewer.sub_viewport.world_2d = get_tree().root.world_2d
	char_converter.button_previewer.preview_target = button_cropper.button_crop_zone
	
	char_converter.button_maker_toggled.connect(_on_button_maker_toggled)


func _on_button_maker_toggled(toggled_on: bool) -> void:
	button_cropper.visible = toggled_on
