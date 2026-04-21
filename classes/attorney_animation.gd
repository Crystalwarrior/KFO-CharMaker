extends Node2D
class_name AttorneyAnimation

@export var animation: Animation

var frame_sprite: Sprite2D
var frame_textures: Array[ImageTexture]

func add_frames_from_folder(folder_path: String) -> void:
	if not frame_sprite:
		frame_sprite = Sprite2D.new()
		frame_sprite.name = "Sprite"
		#frame_sprite.centered = false
		add_child(frame_sprite)
	frame_textures.clear()
	var frame_files: Array = DirAccess.get_files_at(folder_path)
	# There's no simple function to call to do natural sorting, so we gotta
	# make do with a custom sorting function ([0, 1, 2] instead of [0, 1, 10, 11, 2])
	frame_files.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) < 0)
	
	for i: int in frame_files.size():
		var file_name: String = frame_files[i]
		var image: Image = Image.new()
		var image_path: String = folder_path + file_name
		image.load(image_path)
		var image_texture: ImageTexture = ImageTexture.new()
		image_texture.set_image(image)
		frame_textures.append(image_texture)

func initialize_from_frame_data(frame_data: Array[Dictionary]) -> void:
	animation = Animation.new()
	var track_index: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, name + "/Sprite:texture")
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)
	
	var current_time: float = 0.0
	for i: int in frame_data.size():
		var frame: Dictionary = frame_data[i]
		animation.track_insert_key(track_index, current_time, frame_textures[i])
		animation.loop_mode = Animation.LOOP_LINEAR
		current_time += frame["delay"] * 0.01
	animation.length = current_time
