extends Node
class_name TickManager

signal tick_updated(current_seconds)
signal day_ended

const DAY_LENGTH := 300.0
var time_scale := 1.0

var seconds_in_day := 0.0
var ticking := true

var tick_accumulator := 0.0   # <-- NEW

func _process(delta):
	if not ticking:
		return

	var scaled_delta : float = delta * time_scale

	# Advance time
	seconds_in_day += scaled_delta
	tick_accumulator += scaled_delta   # <-- accumulate time

	# Emit tick once per second
	if tick_accumulator >= 1.0:
		tick_accumulator -= 1.0
		emit_signal("tick_updated")

	# End of day logic
	if seconds_in_day >= DAY_LENGTH:
		_end_day()

func _end_day():
	seconds_in_day = 0.0
	tick_accumulator = 0.0
	emit_signal("day_ended")
	print("Day ended!")

# Optional controls
func start():
	ticking = true

func stop():
	ticking = false

func set_time_scale(scale: float):
	time_scale = scale
