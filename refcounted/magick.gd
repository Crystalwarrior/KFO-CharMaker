extends RefCounted
class_name Magick

# Returns the frame data for each animated frame in the image
func get_frame_data(image_path: String) -> Array[Dictionary]:
	var path: String = ProjectSettings.globalize_path(image_path)
	# get frame times
	var output: Array
	OS.execute("magick", [
		# %m	image file format (file magic)
		# %T	image time delay (in centi-seconds)
		# %X	page (canvas) x offset (including sign)
		# %Y	page (canvas) y offset (including sign)
		# %D	image GIF dispose method
		"identify", "-format", "%T %X %Y %D;",
		ProjectSettings.globalize_path(path)
	], output)
	var arg: String = output[0]
	var frames: PackedStringArray = arg.split(";", false)
	var frame_data: Array[Dictionary] = []
	for i: int in frames.size():
		var frame: String = frames[i]
		var data: Dictionary = {}
		var args: PackedStringArray = frame.split(" ")
		data["delay"] = int(args[0])
		data["offset_x"] = int(args[1])
		data["offset_y"] = int(args[2])
		data["dispose"] = args[3]
		frame_data.append(data)
	return frame_data

func split_frames(image_path: String, output_folder: String) -> void:
	var path: String = ProjectSettings.globalize_path(image_path)
	DirAccess.make_dir_recursive_absolute(output_folder)
	var output: Array
	OS.execute("magick", [
		path,
		"-coalesce",
		"-define",
		"webp:lossless=true",
		output_folder + "%d.webp"
	], output)
