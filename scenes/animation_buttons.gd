class_name AnimationButtons
extends Control

@onready var play_backwards_button: Button = %PlayBackwardsButton
@onready var play_start_backwards_button: Button = %PlayStartBackwardsButton
@onready var stop_button: Button = %StopButton
@onready var pause_button: Button = %PauseButton
@onready var play_start_button: Button = %PlayStartButton
@onready var play_button: Button = %PlayButton
@onready var animation_slider: HSlider = %AnimationSlider
@onready var animation_position: SpinBox = %AnimationPosition

var animation_player: AnimationPlayer


func _ready() -> void:
	set_animation_player(animation_player)

	play_backwards_button.pressed.connect(_on_play_backwards_pressed)
	play_start_backwards_button.pressed.connect(_on_play_start_backwards_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	pause_button.pressed.connect(_on_pause_pressed)
	play_start_button.pressed.connect(_on_play_start_pressed)
	play_button.pressed.connect(_on_play_pressed)

	animation_slider.value_changed.connect(_on_animation_slider_changed)
	animation_position.value_changed.connect(_on_animation_slider_changed)


func _process(_delta: float) -> void:
	if not animation_player or animation_player.current_animation.is_empty():
		return
	animation_position.max_value = animation_player.current_animation_length
	animation_slider.max_value = animation_player.current_animation_length
	if animation_player.is_playing():
		update_sliders(animation_player.current_animation_position)


func set_animation_player(to_player: AnimationPlayer) -> void:
	if animation_player and animation_player.animation_started.is_connected(_on_animation_started):
		animation_player.animation_started.disconnect(_on_animation_started)
	animation_player = to_player
	set_disabled(animation_player == null)
	if animation_player:
		animation_player.animation_started.connect(_on_animation_started)


func set_disabled(value: bool) -> void:
	play_backwards_button.disabled = value
	play_start_backwards_button.disabled = value
	stop_button.disabled = value
	pause_button.disabled = value
	play_start_button.disabled = value
	play_button.disabled = value
	animation_slider.editable = not value
	animation_slider.scrollable = not value
	animation_position.editable = not value


func _on_animation_slider_changed(value: float) -> void:
	animation_player.seek(value)
	animation_player.advance(0.0)
	update_sliders(animation_player.current_animation_position)


func _on_animation_started(_anim_name: StringName) -> void:
	stop_button.hide()
	pause_button.show()


func _on_play_backwards_pressed() -> void:
	animation_player.play_backwards()


func _on_play_start_backwards_pressed() -> void:
	animation_player.seek(animation_player.current_animation_length)
	update_sliders(animation_player.current_animation_length)
	animation_player.play_backwards()


func _on_stop_pressed() -> void:
	animation_player.seek(0.0)
	update_sliders(0.0)
	animation_player.stop()


func _on_pause_pressed() -> void:
	animation_player.pause()
	stop_button.show()
	pause_button.hide()


func _on_play_start_pressed() -> void:
	animation_player.seek(0.0)
	animation_player.play()


func _on_play_pressed() -> void:
	animation_player.play()


func update_sliders(to_position: float) -> void:
	animation_position.set_value_no_signal(to_position)
	animation_slider.set_value_no_signal(to_position)
