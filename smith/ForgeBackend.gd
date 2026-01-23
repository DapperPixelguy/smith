extends Node

var ActiveItem = null
var ForgeTime = 0
var ForgeInactive = true
var ForgeQueue = []
var StallSlots = [null, null, null, null, null, null, null, null, null, null]
var StallMaxSlots = 10
signal stall_updated

func _ready():
	TimeManager.tick_updated.connect(_ForgeTickDown)

func _ForgeTickDown():
	if ForgeInactive:
		_activate_next_item()
		return
	
	ForgeTime -= 1
	if ForgeTime <= 0:
		_finish_item()

func add_to_queue(weapon):
	if not _has_resources(weapon):
		return false
	
	_consume_resources(weapon)
	ForgeQueue.append(weapon)
	return true

func _activate_next_item():
	if ForgeQueue.size() == 0:
		ForgeInactive = true
		ActiveItem = null
		return
	
	ActiveItem = ForgeQueue[0]
	ForgeQueue.remove_at(0)
	ForgeTime = ActiveItem["Time"]
	ForgeInactive = false

func _has_resources(item) -> bool:
	return (PlayerStats.PlyrInv["Metal"] >= item["Metal"] and
			PlayerStats.PlyrInv["Wood"] >= item["Wood"] and
			PlayerStats.PlyrInv["Coal"] >= item["Coal"])

func _consume_resources(item):
	PlayerStats.PlyrInv["Metal"] -= item["Metal"]
	PlayerStats.PlyrInv["Wood"] -= item["Wood"]
	PlayerStats.PlyrInv["Coal"] -= item["Coal"]
	
func _finish_item():
	PlayerStats.PlyrInv["Stock"].append(ActiveItem)
	PlayerStats.PlyrStats["PlyrXp"] += 10
	ForgeInactive = true
	ActiveItem = null

func _purchase_res(price):
	if PlayerStats.Shillings >= price:
		PlayerStats.Shillings -= price
		PlayerStats.PlyrInv["Metal"] += 100
		PlayerStats.PlyrInv["Wood"] += 100
		PlayerStats.PlyrInv["Coal"] += 100
		return "Successfully Purchased"
	else:
		return "Not enough Money"

func _add_for_sale(Weapon, Price):
	for i in range(StallSlots.size()):
		if StallSlots[i] == null:
			StallSlots[i] = {
				"Name": Weapon,
				"BaseVal": Price
			}
			return true
	return false

func pull_from_stall(index: int):
	if StallSlots[index] != null:
		# 1. Get the item data
		var item = StallSlots[index]
		
		# 2. Add it back to Stock
		PlayerStats.PlyrInv["Stock"].append(item)
		
		# 3. Empty the stall slot
		StallSlots[index] = null
		
		# 4. Tell the UI to refresh
		# (Assuming you have a signal for this)
		stall_updated.emit()
