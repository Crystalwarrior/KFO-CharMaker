extends Node

func _ready() -> void:
	# Create an HTTP request node and connect its completion signal.
	var http_request: HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var error: Error = http_request.request("https://placehold.co/512.png")
	if error != OK:
		push_error("An error occurred in the HTTP request.")


# Called when the HTTP request is completed.
func _http_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Couldn't be downloaded. Try a different image.")

	var image: Image = Image.new()
	var error: Error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")

	var texture: ImageTexture = ImageTexture.create_from_image(image)

	# Display the image in a TextureRect node.
	var texture_rect: TextureRect = TextureRect.new()
	add_child(texture_rect)
	texture_rect.texture = texture
