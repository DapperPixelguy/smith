extends Node
var ActiveItem = null
var ForgeTime = 0
var ForgeInactive = true
var ForgeQueue = []

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
	# Check if player has enough resources
	if not _has_resources(weapon):
		print("Not enough resources to queue ", weapon["Name"])
		return false
	
	# Consume resources immediately when queuing
	_consume_resources(weapon)
	
	# Add to queue
	ForgeQueue.append(weapon)
	print("Queued ", weapon["Name"], " for forging")
	return true

func _activate_next_item():
	if ForgeQueue.size() == 0:
		ForgeInactive = true
		ActiveItem = null
		return
	
	# Resources already consumed, just start forging
	ActiveItem = ForgeQueue[0]
	ForgeQueue.remove_at(0)
	ForgeTime = ActiveItem["Time"]
	ForgeInactive = false
	print("Started forging: ", ActiveItem["Name"])

func _has_resources(item) -> bool:
	return (PlayerStats.PlyrInv["Metal"] >= item["Metal"] and
			PlayerStats.PlyrInv["Wood"] >= item["Wood"] and
			PlayerStats.PlyrInv["Coal"] >= item["Coal"])

func _consume_resources(item):
	PlayerStats.PlyrInv["Metal"] -= item["Metal"]
	PlayerStats.PlyrInv["Wood"] -= item["Wood"]
	PlayerStats.PlyrInv["Coal"] -= item["Coal"]
	print("Consumed resources for ", item["Name"])
	
func _finish_item():
	# Add the finished weapon to player inventory
	PlayerStats.PlyrInv["Stock"].append(ActiveItem)
	print("Finished forging: ", ActiveItem["Name"])
	
	# Grant XP to the player
	PlayerStats.PlyrStats["PlyrXp"] += 10
	
	# Mark as inactive (will trigger next item on next tick)
	ForgeInactive = true
	ActiveItem = null

func _purchase_res(price):
	if PlayerStats.PlyrInv["Shillings"] > price:
		PlayerStats.PlyrInv["Metal"] += 100
		PlayerStats.PlyrInv["Wood"] += 100
		PlayerStats.PlyrInv["Coal"] += 100
		return "Successfully Purchased"
	else:
		return "Not enough Money"
