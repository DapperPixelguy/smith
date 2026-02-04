extends Node
class_name TickManager

signal tick_updated() # Removed parameter to match your existing signal calls
signal day_ended(day_number)
signal week_ended

const DAY_LENGTH := 10
const DAYS_PER_WEEK := 7

var time_scale := 1.0
var seconds_in_day := 0.0
var ticking := true
var tick_accumulator := 0.0

# --- WEEK TRACKING ---
var current_day_index := 1 # Tracks 1 through 7

func _process(delta):
	if not ticking:
		return

	var scaled_delta : float = delta * time_scale

	# Advance time
	seconds_in_day += scaled_delta
	tick_accumulator += scaled_delta

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
	
	emit_signal("day_ended", current_day_index)
	print("Day ", current_day_index, " ended!")
	
	# Increment week logic
	if current_day_index >= DAYS_PER_WEEK:
		current_day_index = 1
		emit_signal("week_ended")
		print("Week completed!")
	else:
		current_day_index += 1

# Optional controls
func start():
	ticking = true

func stop():
	ticking = false

func set_time_scale(scale: float):
	time_scale = scale
