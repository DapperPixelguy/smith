extends Node2D

@onready var ButtonContainer = $PanelContainer/ScrollContainer/VBoxContainer

func _ready():
	_create_weapon_buttons()

func _create_weapon_buttons():
	for category in ForgeMould._Weapons.keys():
		var category_label = Label.new()
		category_label.text = category
		ButtonContainer.add_child(category_label)
		
		for weapon_name in ForgeMould._Weapons[category].keys():
			var weapon = ForgeMould._Weapons[category][weapon_name]
			var button = Button.new()
			button.text = weapon["Name"] + " (⚙️" + str(weapon["Metal"]) + " 🪵" + str(weapon["Wood"]) + " ⚫" + str(weapon["Coal"]) + ")"
			
			# Store weapon data in button metadata so we can check it later
			button.set_meta("weapon", weapon)
			
			button.pressed.connect(_on_weapon_button_pressed.bind(weapon))
			ButtonContainer.add_child(button)
	
	# Initial button state update
	_update_button_states()

func _update_button_states():
	# Loop through all children in the container
	for child in ButtonContainer.get_children():
		if child is Button and child.has_meta("weapon"):
			var weapon = child.get_meta("weapon")
			var can_afford = _can_afford_weapon(weapon)
			
			# Get the base button text (without the indicator)
			var base_text = weapon["Name"] + " (⚙️" + str(weapon["Metal"]) + " 🪵" + str(weapon["Wood"]) + " ⚫" + str(weapon["Coal"]) + ")"
			
			if can_afford:
				child.text = "✓ " + base_text
				child.disabled = false
			else:
				child.text = "✗ " + base_text
				child.disabled = true

func _can_afford_weapon(weapon) -> bool:
	return (PlayerStats.PlyrInv["Metal"] >= weapon["Metal"] and
			PlayerStats.PlyrInv["Wood"] >= weapon["Wood"] and
			PlayerStats.PlyrInv["Coal"] >= weapon["Coal"])

func _on_weapon_button_pressed(weapon):
	if ForgeBackend.add_to_queue(weapon):
		print("Successfully added ", weapon["Name"], " to forge queue")
	else:
		print("Failed to add ", weapon["Name"], " - not enough resources")
	$Label.text = str(PlayerStats.PlyrInv)
