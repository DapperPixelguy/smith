extends Node2D

@onready var ButtonContainer = $WeaponTray/ScrollContainer/VBoxContainer
var TrayOpened = false
var original_pos : Vector2 # Stores the 'Home' position of the hammer
var gyrate = false

func _ready():
	# 1. Initialize Hammer Position
	# We save the position you set in the editor so the twitch knows where to return
	original_pos = $Hammer.position 
	
	# 2. Create Pixel-Perfect Click Mask
	# This ensures clicks only register on the visible pixels of the hammer
	var texture = $Hammer.texture_normal
	if texture:
		var image = texture.get_image()
		var bitmap = BitMap.new()
		bitmap.create_from_image_alpha(image, 0.1) 
		$Hammer.texture_click_mask = bitmap
	
	# 3. Setup UI State
	$WeaponTray.visible = false
	_create_weapon_buttons()
	
	# 4. Connect Signals
	$Hammer.button_down.connect(_on_hammer_pressed)
	TimeManager.tick_updated.connect(_update_display)

func _input(event):
	# Check if it's a mouse click AND the tray is actually open
	if event is InputEventMouseButton and event.pressed and TrayOpened:
		# Get the local mouse position relative to the Tray and the Hammer
		var mouse_pos = get_global_mouse_position()
		
		# Check if the click is OUTSIDE the Tray's area
		var clicked_on_tray = $WeaponTray.get_global_rect().has_point(mouse_pos)
		# Check if the click is OUTSIDE the Hammer's area (so we don't double-toggle)
		var clicked_on_hammer = $Hammer.get_global_rect().has_point(mouse_pos)
		
		if not clicked_on_tray and not clicked_on_hammer:
			_close_tray()

# Update your toggle function to be cleaner
func _on_hammer_pressed():
	if TrayOpened:
		_close_tray()
	else:
		_open_tray()

func _open_tray():
	TrayOpened = true
	$WeaponTray.visible = true
	# If you add an animation later, play it here

func _close_tray():
	TrayOpened = false
	$WeaponTray.visible = false

func _process(_delta):
	# The Twitch Logic: Runs every frame
	if $Hammer.is_hovered() and !TrayOpened:
		# Randomly offset the position by a tiny amount relative to Home
		$Hammer.position.x = original_pos.x + randf_range(-2.0, 2.0)
		$Hammer.position.y = original_pos.y + randf_range(-1.0, 1.0)
	else:
		# If not hovered, ensure it's sitting exactly at the original position
		if $Hammer.position != original_pos:
			$Hammer.position = original_pos

func _create_weapon_buttons():
	# Clear existing buttons if any (useful for refreshing)
	for n in ButtonContainer.get_children():
		n.queue_free()
		
	for category in ForgeMould._Weapons.keys():
		var category_label = Label.new()
		category_label.text = "--- " + category + " ---"
		category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ButtonContainer.add_child(category_label)
		
		for weapon_name in ForgeMould._Weapons[category].keys():
			var weapon = ForgeMould._Weapons[category][weapon_name]
			var button = Button.new()
			
			# Store weapon data in button metadata so we can check it later
			button.set_meta("weapon", weapon)
			
			# Initial text setting
			button.text = weapon["Name"] + " (⚙️" + str(weapon["Metal"]) + " 🪵" + str(weapon["Wood"]) + " ⚫" + str(weapon["Coal"]) + ")"
			
			button.pressed.connect(_on_weapon_button_pressed.bind(weapon))
			ButtonContainer.add_child(button)
	
	_update_button_states()

func _update_display():
	_update_button_states()
	# Assuming your Label shows the player's current inventory
	$Label.text = "Inventory: " + str(PlayerStats.PlyrInv)

func _update_button_states():
	for child in ButtonContainer.get_children():
		if child is Button and child.has_meta("weapon"):
			var weapon = child.get_meta("weapon")
			var can_afford = _can_afford_weapon(weapon)
			
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
		# Optional: Close tray after selecting
		# _on_hammer_pressed() 
	else:
		print("Failed to add ", weapon["Name"], " - not enough resources")


	
