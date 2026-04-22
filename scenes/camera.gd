class_name DragCamera2D
extends Camera2D

@export var camera_reset_point: Marker2D

var zoom_speed_factor = 1.1

signal zoom_changed()


func zoom_increment(increment_count: int) -> void:
	var current_zoom_step: float = round(log(zoom.x) / log(zoom_speed_factor))
	zoom = Vector2(1.0, 1.0) * pow(zoom_speed_factor, current_zoom_step + increment_count)
	zoom_changed.emit()


func reset_zoom() -> void:
	zoom = Vector2(1.0, 1.0)
	zoom_changed.emit()


func center() -> void:
	if camera_reset_point:
		position = camera_reset_point.position
	else:
		position = Vector2(0, 0)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		get_viewport().gui_release_focus()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_increment(1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_increment(-1)
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			position -= event.relative / zoom.x


func _process(delta):
	var input_direction = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if input_direction != Vector2(0, 0):
		position += (input_direction * 500 / zoom.x) * delta
	if Input.is_action_just_pressed(&"zoom_in"):
		zoom_increment(6)
	if Input.is_action_just_pressed(&"zoom_out"):
		zoom_increment(-6)
