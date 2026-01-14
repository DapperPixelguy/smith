extends Node

var ActiveItem = null
var ForgeTime = 0
var ForgeInactive = true
var ForgeQueue = null

func _ready():
	ForgeQueue = [ForgeMould._Weapons["Swords"]["Broadsword"]]
	TimeManager.tick_updated.connect(_ForgeTickDown)

func _ForgeTickDown():
	print(ActiveItem, ForgeTime)
	if ForgeInactive:
		_activate_next_item()
		return

	ForgeTime -= 1

	if ForgeTime <= 0:
		_finish_item()
		_activate_next_item()

func _activate_next_item():
	if ForgeQueue.size() == 0:
		ForgeInactive = true
		ActiveItem = null
		return

	ActiveItem = ForgeQueue[0]
	ForgeTime = ActiveItem["Time"]
	ForgeInactive = false

func _finish_item():
	PlayerStats.PlyrInv["Stock"].append(ActiveItem)
	PlayerStats.PlyrStats["PlyrXp"] += 10
	ForgeQueue.remove_at(0)
	ForgeInactive = true
