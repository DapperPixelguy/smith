extends Node

@onready var slot_grid = $GridContainer # Adjust path if it's inside a CanvasLayer

func _ready():
	update_stall_ui()
	# Update whenever a game tick happens (market shifts, sales, etc.)
	TimeManager.tick_updated.connect(update_stall_ui)

func update_stall_ui():
	if not slot_grid: return

	for child in slot_grid.get_children():
		child.queue_free()
	
	for i in range(ForgeBackend.StallSlots.size()):
		var slot_data = ForgeBackend.StallSlots[i]
		
		# Use a Button instead of a PanelContainer for interactivity
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(100, 100)
		
		if slot_data == null:
			slot_button.text = "EMPTY"
			slot_button.disabled = true # Can't click an empty slot
		else:
			slot_button.text = str(slot_data["Name"], "\n", slot_data["BaseVal"], "s")
			
			# Connect the click signal using a 'lambda' to pass the index
			slot_button.pressed.connect(func(): _on_slot_clicked(i))
			
		slot_grid.add_child(slot_button)

# The local helper to trigger the backend
func _on_slot_clicked(index: int):
	ForgeBackend.pull_from_stall(index)
	update_stall_ui() # Refresh visuals immediately
	
	
