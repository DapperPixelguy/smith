# TickManager.gd
extends Node
class_name TickManager

# Signals
signal tick_updated(current_seconds)
signal day_ended

# Config
const DAY_LENGTH := 300.0  # seconds per day (5 minutes)
var time_scale := 1.0      # for fast-forward or slow motion

# Internal state
var seconds_in_day := 0.0
var ticking := true

func _process(delta):
	if not ticking:
		return
	
	# Advance time
	seconds_in_day += delta * time_scale
	
	# Emit tick signal for UI or other listeners
	emit_signal("tick_updated", seconds_in_day)
	
	# End of day logic
	if seconds_in_day >= DAY_LENGTH:
		_end_day()

func _end_day():
	seconds_in_day = 0.0
	emit_signal("day_ended")
	print("Day ended!")

# Optional controls
func start():
	ticking = true

func stop():
	ticking = false

func set_time_scale(scale: float):
	time_scale = scale
