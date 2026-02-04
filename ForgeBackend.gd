extends Node

var ActiveItem = null
var ForgeTime = 0
var ForgeInactive = true
var ForgeQueue = []
var StallSlots = [null, null, null, null, null, null, null, null, null, null]
var StallMaxSlots = 10
signal stall_updated

func _ready():
	TimeManager.tick_updated.connect(_OnTick)

func _OnTick():
	_ForgeTickDown()
	_CustomerPurchase()

func _ForgeTickDown():
	if ForgeInactive:
		_activate_next_item()
		return
	
	ForgeTime -= 1
	if ForgeTime <= 0:
		_finish_item()

func add_to_queue(weapon_data):
	# Aligned with UI keys: "Metal", "Wood", "Coal", "Material"
	if not _has_resources(weapon_data):
		return false
	
	_consume_resources(weapon_data)
	ForgeQueue.append(weapon_data)
	return true

func _has_resources(item) -> bool:
	var mat_type = item["Material"]
	# Using .get() to avoid crashing if the metal type isn't in the dict yet
	var has_metal = PlayerStats.PlyrInv["Metals"].get(mat_type, 0) >= item["Metal"]
	var has_wood = PlayerStats.PlyrInv["Wood"] >= item["Wood"]
	var has_coal = PlayerStats.PlyrInv["Coal"] >= item["Coal"]
	return has_metal and has_wood and has_coal

func _consume_resources(item):
	var mat_type = item["Material"]
	PlayerStats.PlyrInv["Metals"][mat_type] -= item["Metal"]
	PlayerStats.PlyrInv["Wood"] -= item["Wood"]
	PlayerStats.PlyrInv["Coal"] -= item["Coal"]

func _finish_item():
	# Item already has its procedural Edge, Strength, and Balance from the UI
	PlayerStats.PlyrInv["Stock"].append(ActiveItem)
	PlayerStats.PlyrStats["PlyrXp"] += 10
	ForgeInactive = true
	ActiveItem = null

func _activate_next_item():
	if ForgeQueue.size() == 0:
		ForgeInactive = true
		ActiveItem = null
		return
	
	ActiveItem = ForgeQueue[0]
	ForgeQueue.remove_at(0)
	ForgeTime = ActiveItem["Time"]
	ForgeInactive = false

# UPDATED: Now requires a material name to add to the specific metal pool
# Inside ForgeBackend.gd

func buy_material(material_name: String, kingdom_name: String, amount: int) -> String:
	# 1. Get the price from our helper (or calculate it)
	var price_per_unit = _calculate_price(material_name, kingdom_name)
	var total_cost = price_per_unit * amount
	
	# 2. Check if player can afford it
	if PlayerStats.PlyrInv["Shillings"] >= total_cost:
		PlayerStats.PlyrInv["Shillings"] -= total_cost
		
		# 3. Add to the specific metal dictionary
		if not PlayerStats.PlyrInv["Metals"].has(material_name):
			PlayerStats.PlyrInv["Metals"][material_name] = 0
			
		PlayerStats.PlyrInv["Metals"][material_name] += amount
		return "Success"
	else:
		return "Insufficient Shillings"

func _calculate_price(material_name: String, kingdom_name: String) -> int:
	var kingdom = WorldData.Kingdom_List[kingdom_name]
	var base_price = 0
	if material_name in MaterialData.MATERIALS["Metals"]:
		base_price = MaterialData.MATERIALS["Metals"][material_name].get("base_price", 50)
	else:
		base_price = MaterialData.MATERIALS[material_name].get("base_price", 50)
	
	# Geopolitical Modifiers
	var stability_mod = 2.0 - kingdom["Stability"] # Low stability = high price
	var war_mod = 1.5 if kingdom["AtWar"].size() > 0 else 1.0
	
	return int(base_price * stability_mod * war_mod)

# Inside ForgeBackend.gd
func _add_for_sale(weapon_object: Dictionary, price: float):
	for i in range(StallSlots.size()):
		if StallSlots[i] == null:
			# We store the WHOLE dictionary so we keep Edge, Strength, etc.
			StallSlots[i] = weapon_object 
			StallSlots[i]["BaseVal"] = price 
			stall_updated.emit()
			return true
	return false

func pull_from_stall(index: int):
	if StallSlots[index] != null:
		var item = StallSlots[index]
		PlayerStats.PlyrInv["Stock"].append(item)
		StallSlots[index] = null
		stall_updated.emit()

func _CustomerPurchase():
	var occupied_indices = []
	for i in range(StallSlots.size()):
		if StallSlots[i] != null:
			occupied_indices.append(i)
	
	if occupied_indices.is_empty():
		return

	var random_index = occupied_indices.pick_random()
	var item = StallSlots[random_index]

	var base_buy_chance = 0.05 
	var renown_multiplier = 0.01
	var buy_chance = ((PlayerStats.PlyrStats["Renown"] * renown_multiplier) + 1) * base_buy_chance
	
	if randf() < buy_chance:
		_execute_sale(random_index, item)

func _execute_sale(index, item):
	var sale_price = item["BaseVal"]
	
	PlayerStats.PlyrInv["Shillings"] += sale_price
	PlayerStats.PlyrStats["Renown"] += 0.01
	
	StallSlots[index] = null
	stall_updated.emit()
	
	print("SOLD: ", item["Name"], " (Edge: ", item["Edge"], ") for ", sale_price)
