extends Node
var ForgeOpen = false

func _ready():
	TimeManager.day_ended.connect(TickUpdated)
	$CanvasLayer/Button.pressed.connect(TweenForge)
	TimeManager.tick_updated.connect(Ledger)

func TickUpdated():
	return 0

func TweenForge():
	print("TweenForge called!")
	print("ForgeOpen is: ", ForgeOpen)
	print("Current offset: ", $CanvasLayer.offset)
	
	var tween = create_tween()
	if ForgeOpen:
		print("Closing - tweening to: ", get_viewport().get_visible_rect().size.y)
		tween.tween_property($CanvasLayer, "offset:y", get_viewport().get_visible_rect().size.y, 0.5)
		ForgeOpen = false
	else:
		print("Opening - tweening to: 0")
		tween.tween_property($CanvasLayer, "offset:y", 0, 0.5)
		ForgeOpen = true
	
	print("New ForgeOpen state: ", ForgeOpen)

func Ledger():
	# 1. Clear the old list so we don't just keep adding rows forever
	for child in $LedgerPage.get_children():
		child.queue_free()
	
	# 2. Loop through the Stock and create a row for each item
	for i in range(PlayerStats.PlyrInv["Stock"].size()):
		var item = PlayerStats.PlyrInv["Stock"][i]
		
		# Create the Horizontal Row container
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Create the Label (Name and Value)
		var item_info = Label.new()
		item_info.text = item["Name"] + " — " + str(item["BaseValue"]) + " Shillings"
		item_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Pushes the button to the right
		
		# Create the Sell Button
		var sell_btn = Button.new()
		sell_btn.text = " Sell "
		
		# Connect the button - we pass the index 'i' so we know which item to remove
		sell_btn.pressed.connect(_on_sell_pressed.bind(i))
		
		# Assemble the row
		row.add_child(item_info)
		row.add_child(sell_btn)
		
		# Add the row to your VBox LedgerPage
		$LedgerPage.add_child(row)

func _on_sell_pressed(index: int):
	print("KILL YOURSELF ALEX AND GABRIELLA")
