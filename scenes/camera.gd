class_name DragCamera2D
extends Camera2D

@export var camera_reset_point: Marker2D
@onready var grid: ColorRect = %Grid

var zoom_speed_factor: float = 1.1
var max_zoom_increments: float = 50.0
var min_zoom_increments: float = -30.0

signal zoom_changed()


func zoom_increment(increment_count: int) -> void:
	var current_zoom_step: float = round(log(zoom.x) / log(zoom_speed_factor))
	zoom = Vector2(1.0, 1.0) * pow(zoom_speed_factor, clampf(current_zoom_step + increment_count, min_zoom_increments, max_zoom_increments))
	zoom_changed.emit()


func reset_zoom() -> void:
	zoom = Vector2(1.0, 1.0)
	zoom_changed.emit()


func center() -> void:
	if camera_reset_point:
		position = camera_reset_point.position
	else:
		position = Vector2(0, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
		get_viewport().gui_release_focus()
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP and \
		   mouse_button_event.pressed:
			zoom_increment(1)
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and \
		   mouse_button_event.pressed:
			zoom_increment(-1)
	if event is InputEventMouseMotion:
		var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			position -= mouse_motion_event.relative / zoom.x
	if event.is_action_pressed(&"toggle_grid"):
		if grid:
			grid.set_visible(not grid.visible)


func _process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		&"ui_left", &"ui_right", &"ui_up", &"ui_down"
	)
	if input_direction != Vector2(0, 0):
		position += (input_direction * 500 / zoom.x) * delta
	if Input.is_action_just_pressed(&"zoom_in"):
		zoom_increment(6)
	if Input.is_action_just_pressed(&"zoom_out"):
		zoom_increment(-6)
