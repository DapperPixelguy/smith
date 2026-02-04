extends Node2D

@onready var ButtonContainer = $WeaponTray/VBoxContainer/ScrollContainer/VBoxContainer
@onready var MaterialBar = $WeaponTray/VBoxContainer/MaterialSelectionHBox # Ensure this node exists in your scene

var TrayOpened = false
var original_pos : Vector2 
var selected_material = "Grey Iron" # Current 'Active' material

func _ready():
	# 1. Hammer Setup
	original_pos = $Hammer.position 
	var texture = $Hammer.texture_normal
	if texture:
		var image = texture.get_image()
		var bitmap = BitMap.new()
		bitmap.create_from_image_alpha(image, 0.1) 
		$Hammer.texture_click_mask = bitmap
	
	# 2. UI Initialization
	$WeaponTray.visible = false
	_create_material_tabs() # Build the top selector
	_create_weapon_buttons()   # Build the weapon list
	
	# 3. Signals
	$Hammer.button_down.connect(_on_hammer_pressed)
	TimeManager.tick_updated.connect(_update_display)

func _on_hammer_pressed():
	if TrayOpened: _close_tray()
	else: _open_tray()

func _open_tray():
	TrayOpened = true
	$WeaponTray.visible = true
	_create_material_tabs()
	_create_weapon_buttons()

func _close_tray():
	TrayOpened = false
	$WeaponTray.visible = false

# --- MATERIAL SELECTION LOGIC ---

func _create_material_tabs():
	# Clears the horizontal bar at the top of the tray
	for n in MaterialBar.get_children():
		n.queue_free()
		
	for mat_name in MaterialData.MATERIALS["Metals"].keys():
		var btn = Button.new()
		# Use a short name or icon for the tab
		btn.text = mat_name.left(5) 
		btn.tooltip_text = mat_name
		
		# Highlight the currently selected material
		if mat_name == selected_material:
			btn.modulate = Color(1.5, 1.5, 1.5) # Glow effect
		else:
			btn.modulate = Color(0.7, 0.7, 0.7) # Dimmed
			
		btn.pressed.connect(_on_material_selected.bind(mat_name))
		MaterialBar.add_child(btn)

func _on_material_selected(mat_name):
	selected_material = mat_name
	_create_material_tabs() # Refresh highlights
	_create_weapon_buttons()   # Refresh weapon stats/costs in the list

# --- WEAPON LIST LOGIC ---

func _create_weapon_buttons():
	for n in ButtonContainer.get_children():
		n.queue_free()
		
	for category in ForgeMould._Weapons.keys():
		var cat_label = Label.new()
		cat_label.text = "--- " + category + " ---"
		cat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ButtonContainer.add_child(cat_label)
		
		for weapon_name in ForgeMould._Weapons[category].keys():
			var mould = ForgeMould._Weapons[category][weapon_name]
			var weapon_data = _generate_procedural_weapon(mould, selected_material)
			
			var btn = Button.new()
			btn.set_meta("weapon", weapon_data)
			
			# Compact UI: Name on top, stats on bottom
			btn.text = "%s\n[E:%.1f S:%.1f B:%.1f]" % [
				weapon_data["Name"], 
				weapon_data["Edge"], 
				weapon_data["Strength"], 
				weapon_data["Balance"]
			]
			
			# Apply material color to the text
			var mat_color = MaterialData.MATERIALS["Metals"][selected_material].get("color", Color.WHITE)
			btn.add_theme_color_override("font_color", mat_color)
			
			btn.pressed.connect(_on_weapon_button_pressed.bind(weapon_data))
			ButtonContainer.add_child(btn)
	
	_update_button_states()

func _generate_procedural_weapon(mould, mat_name):
	var mat = MaterialData.MATERIALS["Metals"][mat_name]
	
	return {
		"Name": mat_name + " " + mould["Name"],
		"Material": mat_name,
		"Metal": mould["Metal"],
		"Wood": mould["Wood"],
		"Coal": mould["Coal"],
		"Time": mould["Time"],
		"Edge": mould["BaseEdge"] * mat["edge"],
		"Strength": mould["BaseStrength"] * mat["strength"],
		"Balance": mould["BaseBalance"] * mat["balance"],
		"BaseVal": mould["BaseVal"] * ((mat["edge"] + mat["strength"] + mat["balance"]) / 3.0)
	}

# --- STATS & UTILITY ---

func _update_display():
	_update_button_states()
	$Label.text = "Resources: " + str(PlayerStats.PlyrInv["Metals"].get(selected_material, 0)) + " " + selected_material

func _update_button_states():
	for child in ButtonContainer.get_children():
		if child is Button and child.has_meta("weapon"):
			var weapon = child.get_meta("weapon")
			child.disabled = ! _can_afford_weapon(weapon)

func _can_afford_weapon(weapon) -> bool:
	var metal_stock = PlayerStats.PlyrInv["Metals"].get(weapon["Material"], 0)
	return (metal_stock >= weapon["Metal"] and
			PlayerStats.PlyrInv["Wood"] >= weapon["Wood"] and
			PlayerStats.PlyrInv["Coal"] >= weapon["Coal"])

func _on_weapon_button_pressed(weapon):
	if ForgeBackend.add_to_queue(weapon):
		print("Added to Forge: ", weapon["Name"])
	else:
		print("Failed: Resources missing.")

func _process(_delta):
	if $Hammer.is_hovered() and !TrayOpened:
		$Hammer.position = original_pos + Vector2(randf_range(-2, 2), randf_range(-1, 1))
	else:
		$Hammer.position = original_pos
