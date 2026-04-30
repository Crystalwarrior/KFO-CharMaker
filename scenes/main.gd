extends Node


@onready var button_cropper: ReferenceRect = %ButtonCropper
@onready var capture_button: Button = %CaptureButton
@onready var sub_viewport_container: SubViewportContainer = %SubViewportContainer
@onready var sub_viewport: SubViewport = %SubViewport
@onready var sub_viewport_camera: Camera2D = %SubViewportCamera
@onready var center_ref: ColorRect = %CenterRef
@onready var char_converter: Control = %CharConverter
@onready var button_bg: TextureRect = %ButtonBG
@onready var button_fg: TextureRect = %ButtonFG

var is_image_off

func _ready() -> void:
	sub_viewport.world_2d = get_tree().root.world_2d
	capture_button.pressed.connect(_on_capture_button_pressed)
	get_tree().root.set_canvas_cull_mask_bit(1, false)
	char_converter.button_image_selected.connect(_on_button_image_selected)
	char_converter.button_image_deleted.connect(_on_button_image_deleted)
	char_converter.capture_mode.connect(_activate_capture_mode)


func _process(delta: float) -> void:
	sub_viewport_camera.position = button_cropper.position + button_cropper.button_crop_zone.position
	
	var prev_position: Vector2 = sub_viewport_container.position
	var prev_size_x: float = sub_viewport_container.size.x
	sub_viewport_container.set_size(button_cropper.button_crop_zone.size - Vector2(10, 10))


func _on_capture_button_pressed() -> void:
	var button
	if is_image_off:
		button = char_converter.off_button_icon
	else:
		button = char_converter.on_button_icon
	await RenderingServer.frame_post_draw
	button.texture = ImageTexture.create_from_image(sub_viewport.get_texture().get_image())
	capture_button.visible = false
	sub_viewport_container.visible = false
	button_cropper.visible = false
	char_converter.button_image_buttons.visible = false

func _on_button_image_selected(texture: ImageTexture, is_bg) -> void:
	if is_bg:
		button_bg.texture = texture
	else:
		button_fg.texture = texture

func _on_button_image_deleted(is_bg) -> void:
	if is_bg:
		button_bg.texture = null
	else:
		button_fg.texture = null

func _activate_capture_mode(is_off) -> void:
	is_image_off = is_off
	capture_button.visible = true
	sub_viewport_container.visible = true
	button_cropper.visible = true
