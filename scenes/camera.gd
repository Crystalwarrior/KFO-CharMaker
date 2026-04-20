extends Camera2D

@export var camera_reset_point: Marker2D

var zoom_speed = 0.1

func _unhandled_input(event):
	if event is InputEventMouseButton:
		get_viewport().gui_release_focus()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom += zoom * zoom_speed
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom -= zoom * zoom_speed
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			position -= (event.relative / zoom.x)


func _process(delta):
	var input_direction = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	if input_direction != Vector2(0, 0):
		position += (input_direction * 500 / zoom.x) * delta
	if Input.is_action_pressed("zoom_in"):
		_on_main_window_zoom(0.5)
	if Input.is_action_pressed("zoom_out"):
		_on_main_window_zoom(-0.5)


func _on_main_window_zoom(amt):
	zoom += zoom * amt * zoom_speed


func _on_main_window_reset_camera():
	zoom = Vector2(1, 1)
	if camera_reset_point:
		position = camera_reset_point.position
	else:
		position = Vector2(0, 0)
