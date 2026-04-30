extends Control


@export var resize_width: int = 8
@export var preserve_aspect_ratio: bool = true


@onready var button_crop_zone: Control = %ButtonCropZone
@onready var size_label: Label = %SizeLabel


enum DragMode {
	LEFT, TOP_LEFT, TOP, TOP_RIGHT, RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, MOVE,
}


const _LEFT_MODES = [DragMode.LEFT, DragMode.TOP_LEFT, DragMode.BOTTOM_LEFT]
const _RIGHT_MODES = [DragMode.RIGHT, DragMode.TOP_RIGHT, DragMode.BOTTOM_RIGHT]
const _TOP_MODES = [DragMode.TOP, DragMode.TOP_LEFT, DragMode.TOP_RIGHT]
const _BOTTOM_MODES = [DragMode.BOTTOM, DragMode.BOTTOM_LEFT, DragMode.BOTTOM_RIGHT]
const _HORIZONTAL_EDGE_MODES = [DragMode.LEFT, DragMode.RIGHT]
const _VERTICAL_EDGE_MODES = [DragMode.TOP, DragMode.BOTTOM]
const _CORNER_MODES = [DragMode.TOP_LEFT, DragMode.TOP_RIGHT, DragMode.BOTTOM_LEFT, DragMode.BOTTOM_RIGHT]


var drag_mode: DragMode = DragMode.MOVE
var dragging = false
var drag_start_global: Vector2
var initial_global_pos: Vector2
var initial_size: Vector2


func _process(_delta: float) -> void:
	size_label.text = "%dx%d" % [button_crop_zone.size.x, button_crop_zone.size.y]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_start_global = get_global_mouse_position().round()
			initial_global_pos = global_position
			initial_size = size
			drag_mode = _detect_mode(event.position)[0]
		else:
			dragging = false
		return

	if event is InputEventMouseMotion:
		if dragging:
			_handle_drag()
			return
		var result = _detect_mode(event.position)
		drag_mode = result[0]
		mouse_default_cursor_shape = result[1]


func _detect_mode(local_pos: Vector2) -> Array:
	var in_left = local_pos.x < resize_width
	var in_right = local_pos.x > size.x - resize_width
	var in_top = local_pos.y < resize_width
	var in_bottom = local_pos.y > size.y - resize_width

	if in_left and in_top: return [DragMode.TOP_LEFT, Control.CURSOR_FDIAGSIZE]
	if in_right and in_bottom: return [DragMode.BOTTOM_RIGHT, Control.CURSOR_FDIAGSIZE]
	if in_right and in_top: return [DragMode.TOP_RIGHT, Control.CURSOR_BDIAGSIZE]
	if in_left and in_bottom: return [DragMode.BOTTOM_LEFT, Control.CURSOR_BDIAGSIZE]
	if in_left: return [DragMode.LEFT, Control.CURSOR_HSIZE]
	if in_right: return [DragMode.RIGHT, Control.CURSOR_HSIZE]
	if in_top: return [DragMode.TOP, Control.CURSOR_VSIZE]
	if in_bottom: return [DragMode.BOTTOM, Control.CURSOR_VSIZE]
	return [DragMode.MOVE, Control.CURSOR_MOVE]


func _handle_drag() -> void:
	if drag_mode == DragMode.MOVE:
		global_position = initial_global_pos + (get_global_mouse_position() - drag_start_global).round()
		return

	var delta = get_global_mouse_position() - drag_start_global
	var delta_x = 0.0
	var delta_y = 0.0
	if drag_mode in _LEFT_MODES: delta_x = -delta.x
	elif drag_mode in _RIGHT_MODES: delta_x = delta.x
	if drag_mode in _TOP_MODES: delta_y = -delta.y
	elif drag_mode in _BOTTOM_MODES: delta_y = delta.y
	var new_w = initial_size.x + delta_x
	var new_h = initial_size.y + delta_y

	if preserve_aspect_ratio:
		var size_diff = _get_aspect_diff(new_w, new_h)
		new_w = initial_size.x + size_diff
		new_h = initial_size.y + size_diff

	new_w = max(resize_width, new_w)
	new_h = max(resize_width, new_h)

	var adjust_x = (initial_size.x - new_w) if (drag_mode in _LEFT_MODES) else 0.0
	var adjust_y = (initial_size.y - new_h) if (drag_mode in _TOP_MODES) else 0.0

	# Center non-dragged axis for edge-only drags (keeps middle anchor)
	if drag_mode in _HORIZONTAL_EDGE_MODES:
		adjust_y -= (new_h - initial_size.y) / 2.0
	elif drag_mode in _VERTICAL_EDGE_MODES:
		adjust_x -= (new_w - initial_size.x) / 2.0

	global_position = Vector2(initial_global_pos.x + adjust_x, initial_global_pos.y + adjust_y)
	size = Vector2(new_w, new_h)

	global_position = global_position.round()
	size = size.round()


func _get_aspect_diff(raw_w: float, raw_h: float) -> float:
	if drag_mode in _HORIZONTAL_EDGE_MODES:
		return raw_w - initial_size.x
	if drag_mode in _VERTICAL_EDGE_MODES:
		return raw_h - initial_size.y
	if drag_mode in _CORNER_MODES:
		return ((raw_w - initial_size.x) + (raw_h - initial_size.y)) / 2.0
	return 0.0
