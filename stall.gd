extends Node

@onready var slot_grid = $GridContainer 

func _ready():
	update_stall_ui()
	TimeManager.tick_updated.connect(update_stall_ui)

func update_stall_ui():
	if not slot_grid: return

	for child in slot_grid.get_children():
		child.queue_free()
	
	for i in range(ForgeBackend.StallSlots.size()):
		var slot_data = ForgeBackend.StallSlots[i]
		
		var slot_button = Button.new()
		
		# 1. ENFORCE BOX LIMITS
		# This stops the button from growing horizontally to fit the text
		slot_button.custom_minimum_size = Vector2(100, 100)
		slot_button.clip_contents = true # Hides text that overflows vertically
		
		# 2. ENABLE TEXT WRAPPING
		# This tells the button to move to a new line instead of stretching
		slot_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		# 3. FONT SIZE ADJUSTMENT
		# Smaller font helps fit the "Name\nPrice" logic into a 100x100 box
		slot_button.add_theme_font_size_override("font_size", 10)

		if slot_data == null:
			slot_button.text = "EMPTY"
			slot_button.disabled = true 
		else:
			# Using \n to force the price onto its own line
			slot_button.text = str(slot_data["Name"], "\n[", slot_data["BaseVal"], "s]")
			slot_button.pressed.connect(func(): _on_slot_clicked(i))
			
		slot_grid.add_child(slot_button)

func _on_slot_clicked(index: int):
	ForgeBackend.pull_from_stall(index)
	update_stall_ui()
