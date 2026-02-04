extends Node3D

@onready var camera_pivot = $CameraPivot
@export var transition_time: float = 0.4

var is_moving: bool = false
var current_view: String = "stall" 

# Using _unhandled_input ensures this only fires if the UI didn't use the key first
func _unhandled_input(event: InputEvent):
	if is_moving or not event is InputEventKey or not event.pressed:
		return

	# A (Flick Left)
	if event.keycode == KEY_A:
		var target = 180 if current_view == "stall" else 0
		_transition_to("forge" if current_view == "stall" else "stall", Vector3(0, target, 0))
	
	# D (Flick Right)
	elif event.keycode == KEY_D:
		var target = -180 if current_view == "stall" else 0 # Or -360 if 0 flips the wrong way
		_transition_to("forge" if current_view == "stall" else "stall", Vector3(0, target, 0))

	# S (Down to Ledger)
	elif event.keycode == KEY_S:
		_transition_to("ledger", Vector3(90, 0, 0))

	# W (Up from Ledger)
	elif event.keycode == KEY_W and current_view == "ledger":
		_transition_to("stall", Vector3.ZERO)
			
func _transition_to(view_name: String, target_rot: Vector3):
	print("Rotating to: ", view_name) 
	is_moving = true
	current_view = view_name
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(camera_pivot, "rotation_degrees", target_rot, transition_time)
	tween.finished.connect(func(): is_moving = false)
