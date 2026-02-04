extends Node3D

@onready var camera_pivot = $CameraPivot
@export var transition_time: float = 0.4

var is_moving: bool = false
var current_view: String = "stall" 

func _unhandled_input(event: InputEvent):
	if is_moving or not event is InputEventKey or not event.pressed:
		return

	var rotation_offset: float = 0.0

	if event.keycode == KEY_A:
		rotation_offset = 180.0
	elif event.keycode == KEY_D:
		rotation_offset = -180.0
	
	if rotation_offset != 0.0:
		# Toggle the view name
		current_view = "forge" if current_view == "stall" else "stall"
		_rotate_relative(rotation_offset)

func _rotate_relative(offset: float):
	is_moving = true
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# Calculate the new target based on CURRENT rotation
	var target_y = camera_pivot.rotation_degrees.y + offset
	
	tween.tween_property(camera_pivot, "rotation_degrees:y", target_y, transition_time)
	
	tween.finished.connect(func(): 
		is_moving = false
		# OPTIONAL: Keep degrees between -180 and 180 so they don't grow forever
		camera_pivot.rotation_degrees.y = fposmod(camera_pivot.rotation_degrees.y + 180.0, 360.0) - 180.0
	)
			
func _transition_to(view_name: String, target_rot: Vector3):
	print("Rotating to: ", view_name) 
	is_moving = true
	current_view = view_name
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(camera_pivot, "rotation_degrees", target_rot, transition_time)
	tween.finished.connect(func(): is_moving = false)
