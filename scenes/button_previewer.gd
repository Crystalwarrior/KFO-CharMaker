extends PanelContainer
class_name ButtonPreviewer

@onready var sub_viewport_container: SubViewportContainer = %SubViewportContainer
@onready var sub_viewport: SubViewport = %SubViewport
@onready var button_bg: TextureRect = %ButtonBG
@onready var button_fg: TextureRect = %ButtonFG
@onready var button_mask: TextureRect = %ButtonMask
@onready var sub_viewport_camera: Camera2D = %SubViewportCamera

var preview_target


func _process(_delta: float) -> void:
	if not preview_target:
		return
	sub_viewport_camera.global_position = preview_target.global_position
	sub_viewport.size = preview_target.size
	button_mask.custom_minimum_size = preview_target.size
