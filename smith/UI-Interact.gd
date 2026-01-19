extends Node
@onready var ButtonContainer = $VBoxContainer  # Change to your container name
@onready var StockContainer = $StockVboxContainer

func _ready():
	TimeManager.tick_updated.connect(TickUpdated)
	_create_weapon_buttons()
	TickUpdated()

func TickUpdated():
	# Clear existing stock display
	for child in StockContainer.get_children():
		child.queue_free()
	
	if PlayerStats.PlyrInv["Stock"].size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Stock: Empty"
		StockContainer.add_child(empty_label)
	else:
		for i in range(PlayerStats.PlyrInv["Stock"].size()):
			var item = PlayerStats.PlyrInv["Stock"][i]
			
			# Create an HBoxContainer for each item (name + sell button)
			var item_row = HBoxContainer.new()
			
			# Item name and value
			var item_label = Label.new()
			item_label.text = item["Name"] + " - " + str(item["BaseVal"]) + " shillings"
			item_row.add_child(item_label)
			
			# Sell button
			var sell_button = Button.new()
			sell_button.text = "Sell"
			sell_button.pressed.connect(_on_sell_button_pressed.bind(i))
			item_row.add_child(sell_button)
			
			StockContainer.add_child(item_row)
	
	_update_button_states()

func _on_sell_button_pressed(stock_index):
	# Safety check: make sure the index is still valid
	if stock_index >= PlayerStats.PlyrInv["Stock"].size():
		print("Invalid stock index - item already sold")
		return
	
	var item = PlayerStats.PlyrInv["Stock"][stock_index]
	var sell_price = item["BaseVal"]
	
	# Add money
	PlayerStats.PlyrInv["Shillings"] += sell_price
	
	# Remove from stock
	PlayerStats.PlyrInv["Stock"].remove_at(stock_index)
	
	print("Sold ", item["Name"], " for ", sell_price, " shillings!")

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
