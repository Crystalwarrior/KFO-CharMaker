extends Control

@onready var zoom_center_button: Button = %ZoomCenterButton
@onready var zoom_less_button: Button = %ZoomLessButton
@onready var zoom_level: Button = %ZoomLevel
@onready var zoom_more_button: Button = %ZoomMoreButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	zoom_center_button.pressed.connect(_on_zoom_center_button_pressed)
	zoom_less_button.pressed.connect(_on_zoom_less_button_pressed)
	zoom_level.pressed.connect(_on_zoom_level_pressed)
	zoom_more_button.pressed.connect(_on_zoom_more_button_pressed)

	# We never have to change cameras more than once right now, so
	# this is good enough so far.
	var camera: DragCamera2D = get_viewport().get_camera_2d()
	if camera:
		camera.zoom_changed.connect(_on_zoom_level_changed)


func _on_zoom_center_button_pressed() -> void:
	var camera: DragCamera2D = get_viewport().get_camera_2d()
	if camera:
		camera.center()


func _on_zoom_less_button_pressed() -> void:
	var camera: DragCamera2D = get_viewport().get_camera_2d()
	if camera:
		camera.zoom_increment(-6)


func _on_zoom_level_changed() -> void:
	var camera: DragCamera2D = get_viewport().get_camera_2d()
	if camera:
		zoom_level.text = str(camera.zoom.x * 100).pad_decimals(1) + " %"
	else:
		zoom_level.text = "??? %"


func _on_zoom_level_pressed() -> void:
	var camera: DragCamera2D = get_viewport().get_camera_2d()
	if camera:
		camera.reset_zoom()


func _on_zoom_more_button_pressed() -> void:
	var camera: DragCamera2D = get_viewport().get_camera_2d()
	if camera:
		camera.zoom_increment(6)
