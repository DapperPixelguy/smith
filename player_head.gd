extends Camera3D

func _process(_delta):
	# We only care about mouse movement and clicks
	_handle_3d_mouse_interaction()

func _handle_3d_mouse_interaction():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = project_ray_origin(mouse_pos)
	var ray_to = ray_from + project_ray_normal(mouse_pos) * 10.0 # 10 meters away
	
	# Check what the "laser" hits
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		# Only act if the object is tagged as a 'viewport_surface'
		if collider.is_in_group("viewport_surface"):
			_pass_mouse_to_viewport(collider, result.position)

func _pass_mouse_to_viewport(collider, hit_position):
	# 1. Find the Sprite and Viewport (Assuming they are siblings/children)
	# You can customize these paths to match your specific setup
	var sprite = collider.get_parent() as Sprite3D
	var viewport = sprite.get_node("../SubViewport") 
	
	if not sprite or not viewport: return

	# 2. Convert 3D world hit to 2D local UV
	var local_pos = sprite.to_local(hit_position)
	
	# Map -0.5/0.5 local range to 0.0/1.0 UV range
	var uv_x = (local_pos.x / sprite.region_rect.size.x) + 0.5
	var uv_y = (local_pos.y / sprite.region_rect.size.y) + 0.5
	
	# 3. Create a fake mouse event for the 2D UI
	var event = InputEventMouseMotion.new() # Or InputEventMouseButton
	event.position = Vector2(uv_x * viewport.size.x, uv_y * viewport.size.y)
	
	# Handle Clicks
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var click = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = event.position
		viewport.push_input(click)
	else:
		viewport.push_input(event)
