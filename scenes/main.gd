extends Node


@onready var button_capture: TextureRect = %ButtonCapture
@onready var button_cropper: ReferenceRect = %ButtonCropper
@onready var capture_button: Button = %CaptureButton
@onready var sub_viewport_container: SubViewportContainer = %SubViewportContainer
@onready var sub_viewport: SubViewport = %SubViewport
@onready var sub_viewport_camera: Camera2D = %SubViewportCamera

func _ready() -> void:
	sub_viewport.world_2d = get_tree().root.world_2d
	capture_button.pressed.connect(_on_capture_button_pressed)


func _process(delta: float) -> void:
	sub_viewport_camera.position = button_cropper.position + button_cropper.button_crop_zone.position
	
	var prev_position: Vector2 = sub_viewport_container.position
	var prev_size_x: float = sub_viewport_container.size.x
	sub_viewport_container.set_size(button_cropper.button_crop_zone.size)


func _on_capture_button_pressed() -> void:
	await RenderingServer.frame_post_draw
	capture_button.icon = ImageTexture.create_from_image(sub_viewport.get_texture().get_image())
