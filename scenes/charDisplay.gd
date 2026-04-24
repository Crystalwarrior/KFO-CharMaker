extends AspectRatioContainer

@onready var preview_texture_rect: TextureRect = %PreviewTextureRect

@export var preview_height: float = 1.0

var position_offset_normal: Vector2 = Vector2(0.0, 0.0)


func _set_aspect():
	var VP_Rect = get_viewport_rect()
	var aspect = VP_Rect.size.x / VP_Rect.size.y

	self.ratio = aspect
	calc_preview_height()


func calc_preview_height():
	var area = self.get_rect()
	var base_position
	preview_texture_rect.size.x = area.size.x
	preview_texture_rect.size.y = preview_height * area.size.y
	preview_texture_rect.position = -preview_texture_rect.size / 2


func _on_aspect_ratio_container_item_rect_changed() -> void:
	#_set_aspect()
	pass
