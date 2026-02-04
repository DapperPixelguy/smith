extends Area3D

# Auto-detect siblings
@onready var viewport = get_parent().get_node("SubViewport")
@onready var sprite = get_parent().get_node("Sprite3D")

func _input_event(_camera, event, event_pos, _normal, _shape_idx):
	if event is InputEventMouse:
		# 1. Translate 3D position to Local 2D Sprite position
		var local_pos = sprite.to_local(event_pos)
		
		# 2. Map to UV coordinates (0 to 1)
		# sprite.get_item_rect().size is the size of the sprite in 3D units
		var size = sprite.get_item_rect().size
		var uv = Vector2(local_pos.x / size.x + 0.5, 0.5 - local_pos.y / size.y)
		
		# 3. Scale to Viewport Pixels
		event.position = uv * Vector2(viewport.size)
		viewport.push_input(event)
