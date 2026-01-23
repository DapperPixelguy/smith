extends Node

var ForgeOpen = false
var TweenOpen = false

func _ready():
	TimeManager.day_ended.connect(TickUpdated)
	$CanvasLayer/Button.pressed.connect(TweenForge)
	$CanvasLayer2/Button2.pressed.connect(TweenStall)
	TimeManager.tick_updated.connect(Ledger)

func TickUpdated():
	return 0

func TweenForge():
	# Bring this layer to the front
	$CanvasLayer.layer = 2
	$CanvasLayer2.layer = 1
	
	var tween = create_tween()
	var screen_height = get_viewport().get_visible_rect().size.y
	if ForgeOpen:
		# Slide back UP to hide
		tween.tween_property($CanvasLayer, "offset:y", screen_height, 0.5)
		ForgeOpen = false
	else:
		# Slide DOWN to show
		tween.tween_property($CanvasLayer, "offset:y", 0, 0.5)
		ForgeOpen = true

func TweenStall():
	# Bring this layer to the front
	$CanvasLayer2.layer = 2
	$CanvasLayer.layer = 1
	
	var tween = create_tween()
	var screen_height = get_viewport().get_visible_rect().size.y
	
	if TweenOpen:
		tween.tween_property($CanvasLayer2, "offset:y", 0, 0.5)
		TweenOpen = false
	else:
		tween.tween_property($CanvasLayer2, "offset:y", screen_height, 0.5)
		TweenOpen = true

func Ledger():
	# Clear the current list
	for child in $LedgerPage.get_children():
		child.queue_free()
	
	# Rebuild from the current Stock list
	for i in range(PlayerStats.PlyrInv["Stock"].size()):
		var item = PlayerStats.PlyrInv["Stock"][i]
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var item_info = Label.new()
		item_info.text = item["Name"] + " — " + str(item["BaseVal"]) + " Shillings"
		item_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var sell_btn = Button.new()
		sell_btn.text = " Put On Sale "
		# Bind the current index to the function
		sell_btn.pressed.connect(_on_sell_pressed.bind(item["Name"], item["BaseVal"], i))
		
		row.add_child(item_info)
		row.add_child(sell_btn)
		$LedgerPage.add_child(row)

func _on_sell_pressed(item_name: String, price: int, index: int):
	# If the backend successfully lists the item
	if ForgeBackend._add_for_sale(item_name, price):
		# Remove it from the inventory array
		PlayerStats.PlyrInv["Stock"].pop_at(index)
		# Refresh the Ledger UI so the item disappears immediately
		Ledger()
