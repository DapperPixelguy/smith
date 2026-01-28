extends Node

var ForgeOpen = false
var TweenOpen = false

# Ledger system
var current_page = 0
var pages = []
const ITEMS_PER_PAGE = 10

func _ready():
	TimeManager.day_ended.connect(TickUpdated)
	
	# Connect existing buttons if they exist
	if has_node("CanvasLayer/Button"):
		$CanvasLayer/Button.pressed.connect(TweenForge)
	if has_node("CanvasLayer2/Button2"):
		$CanvasLayer2/Button2.pressed.connect(TweenStall)
	
	TimeManager.tick_updated.connect(Ledger)
	
	# Connect directly to the scroll containers
	$LedgerPage/LeftPageScroll.gui_input.connect(_on_left_page_clicked)
	$LedgerPage/RightPageScroll.gui_input.connect(_on_right_page_clicked)

	# IMPORTANT: Set these so they don't block the buttons inside them
	$LedgerPage/LeftPageScroll.mouse_filter = Control.MOUSE_FILTER_PASS
	$LedgerPage/RightPageScroll.mouse_filter = Control.MOUSE_FILTER_PASS
		
	# Create ledger navigation UI
	_create_ledger_navigation()
	
	# Initialize ledger
	generate_pages()
	display_current_page()
	
func _on_left_page_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_prev_page()

func _on_right_page_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_next_page()

func TickUpdated():
	return 0

func TweenForge():
	$CanvasLayer.layer = 2
	$CanvasLayer2.layer = 1
	
	var tween = create_tween()
	var screen_height = get_viewport().get_visible_rect().size.y
	if ForgeOpen:
		tween.tween_property($CanvasLayer, "offset:y", screen_height, 0.5)
		ForgeOpen = false
	else:
		tween.tween_property($CanvasLayer, "offset:y", 0, 0.5)
		ForgeOpen = true

func TweenStall():
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

# --- LEDGER PAGE SYSTEM ---

func _create_ledger_navigation():
	var page_counter = Label.new()
	page_counter.name = "PageCounter"
	page_counter.text = "Cover"
	page_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$LedgerPage.add_child(page_counter)

func generate_pages():
	pages.clear()
	
	# Index 0: Player Stats
	pages.append({"type": "player_stats"})
	
	# Index 1+: Stock
	var stock_size = PlayerStats.PlyrInv["Stock"].size()
	var stock_pages_needed = ceil(float(stock_size) / ITEMS_PER_PAGE)
	for i in range(max(1, stock_pages_needed)):
		pages.append({
			"type": "stock",
			"start_index": i * ITEMS_PER_PAGE,
			"end_index": min((i + 1) * ITEMS_PER_PAGE, stock_size)
		})
	
	pages.append({"type": "apprentice"})
	pages.append({"type": "resources"})
	pages.append({"type": "kingdom_list"})
	
	for kingdom_name in WorldData.Kingdom_List.keys():
		pages.append({
			"type": "kingdom_detail",
			"kingdom_name": kingdom_name
		})

func display_current_page():
	clear_page_display()
	
	if current_page == 0:
		# Spread 0: [Blank | Stats]
		show_blank_page($LedgerPage/LeftPageScroll/LeftPage)
		display_page_content($LedgerPage/RightPageScroll/RightPage, pages[0])
	else:
		# current_page acts as the Right side anchor
		var left_idx = current_page - 1
		var right_idx = current_page
		
		if left_idx < pages.size():
			display_page_content($LedgerPage/LeftPageScroll/LeftPage, pages[left_idx])
		else:
			show_blank_page($LedgerPage/LeftPageScroll/LeftPage)
			
		if right_idx < pages.size():
			display_page_content($LedgerPage/RightPageScroll/RightPage, pages[right_idx])
		else:
			show_blank_page($LedgerPage/RightPageScroll/RightPage)
	
	_update_page_counter()

func _on_prev_page():
	if current_page <= 2:
		current_page = 0
	else:
		current_page -= 2
	display_current_page()

func _on_next_page():
	if current_page == 0:
		current_page = 2 # Jump to first real spread (Pages 1 & 2)
	elif current_page + 1 < pages.size():
		current_page += 2 # Jump by spread
	display_current_page()

func _update_page_counter():
	var counter = $LedgerPage.get_node("PageCounter")
	if current_page == 0:
		counter.text = "Cover"
	else:
		counter.text = "Pages " + str(current_page) + " - " + str(current_page + 1)

func clear_page_display():
	for child in $LedgerPage/LeftPageScroll/LeftPage.get_children():
		child.queue_free()
	for child in $LedgerPage/RightPageScroll/RightPage.get_children():
		child.queue_free()

func show_blank_page(container):
	var blank = Label.new()
	blank.text = ""
	container.add_child(blank)

func display_page_content(container, page_data):
	match page_data["type"]:
		"player_stats": show_player_stats(container)
		"stock": show_stock_page(container, page_data["start_index"], page_data["end_index"])
		"apprentice": show_apprentice_page(container)
		"resources": show_resources_page(container)
		"kingdom_list": show_kingdom_list(container)
		"kingdom_detail": show_kingdom_detail(container, page_data["kingdom_name"])

func show_resources_page(container):
	var title = Label.new()
	title.text = "=== RESOURCE LEDGER ==="
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.BLACK)
	container.add_child(title)
	
	# Current Stock Display
	var res_list = Label.new()
	res_list.add_theme_font_size_override("font_size", 11)
	res_list.add_theme_color_override("font_color", Color.BLACK)
	
	var metal = PlayerStats.PlyrInv.get("Metal", 0)
	var wood = PlayerStats.PlyrInv.get("Wood", 0)
	var coal = PlayerStats.PlyrInv.get("Coal", 0)
	
	res_list.text = "\n[ CURRENT STOCK ]\n"
	res_list.text += "• Iron/Steel: " + str(metal) + " units\n"
	res_list.text += "• Timber: " + str(wood) + " units\n"
	res_list.text += "• Coal: " + str(coal) + " units\n\n"
	container.add_child(res_list)
	
	# Purchase Section
	var buy_info = Label.new()
	buy_info.add_theme_font_size_override("font_size", 10)
	buy_info.add_theme_color_override("font_color", Color.DARK_SLATE_GRAY)
	buy_info.text = "Bulk Restock (100 units each)"
	container.add_child(buy_info)
	
	var purchase_btn = Button.new()
	purchase_btn.text = "Purchase for 100 Shillings"
	purchase_btn.pressed.connect(_on_purchase_resources)
	container.add_child(purchase_btn)
	
func show_apprentice_page(container):
	var title = Label.new()
	title.text = "=== WORKFORCE & WAGES ==="
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.BLACK)
	container.add_child(title)
	
	var staff_info = Label.new()
	staff_info.add_theme_font_size_override("font_size", 11)
	staff_info.add_theme_color_override("font_color", Color.BLACK)
	
	# Placeholder for active apprentices
	var apprentices = PlayerStats.PlyrInv.get("Apprentices", [])
	
	if apprentices.size() == 0:
		staff_info.text = "\nYour forge is currently quiet.\nNo apprentices are on the payroll.\n\n"
		staff_info.text += "Visit the Town Square to find\nprospective strikers."
	else:
		staff_info.text = "\nActive Apprentices: " + str(apprentices.size()) + "\n"
		staff_info.text += "Daily Wage Total: " + str(apprentices.size() * 15) + "s\n"
	
	container.add_child(staff_info)
	
	# A horizontal rule for style
	var separator = HSeparator.new()
	container.add_child(separator)

func show_player_stats(container):
	var stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color.BLACK)
	stats_label.text = "=== PLAYER STATS ===\n"
	stats_label.text += "XP: " + str(PlayerStats.PlyrStats["PlyrXp"]) + "\n"
	stats_label.text += "Renown: " + str(PlayerStats.PlyrStats["Renown"]) + "\n"
	stats_label.text += "Shillings: " + str(PlayerStats.PlyrInv["Shillings"]) + "\n"
	container.add_child(stats_label)

func show_stock_page(container, start_idx: int, end_idx: int):
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.BLACK)
	title.text = "=== STOCK ===" if start_idx == 0 else "=== STOCK (cont.) ==="
	container.add_child(title)
	
	for i in range(start_idx, end_idx):
		var item = PlayerStats.PlyrInv["Stock"][i]
		var row = HBoxContainer.new()
		var item_info = Label.new()
		item_info.add_theme_font_size_override("font_size", 11)
		item_info.add_theme_color_override("font_color", Color.BLACK)
		item_info.text = item["Name"] + " - " + str(item["BaseVal"])
		item_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var sell_btn = Button.new()
		sell_btn.text = "Sell"
		sell_btn.pressed.connect(_on_sell_pressed.bind(item))
		
		row.add_child(item_info)
		row.add_child(sell_btn)
		container.add_child(row)

func show_kingdom_list(container):
	var title = Label.new()
	title.text = "=== KINGDOMS ===\n"
	title.add_theme_color_override("font_color", Color.BLACK)
	container.add_child(title)
	for kingdom in WorldData.Kingdom_List.keys():
		var btn = Button.new()
		btn.text = kingdom
		btn.pressed.connect(_jump_to_kingdom.bind(kingdom))
		container.add_child(btn)

func show_kingdom_detail(container, kingdom_name: String):
	var kingdom = WorldData.Kingdom_List[kingdom_name]
	var title = Label.new()
	title.text = "=== " + kingdom_name.to_upper() + " ==="
	title.add_theme_color_override("font_color", Color.BLACK)
	container.add_child(title)
	
	var info = Label.new()
	info.add_theme_color_override("font_color", Color.BLACK)
	info.text = "Strength: " + str(kingdom["Strength"]) + "\nStability: " + str(kingdom["Stability"])
	container.add_child(info)
	
	var back_btn = Button.new()
	back_btn.text = "Back to List"
	back_btn.pressed.connect(_jump_to_kingdom_list)
	container.add_child(back_btn)

func _jump_to_kingdom(kingdom_name: String):
	for i in range(pages.size()):
		if pages[i]["type"] == "kingdom_detail" and pages[i]["kingdom_name"] == kingdom_name:
			current_page = i if i % 2 == 0 else i + 1
			display_current_page()
			return

func _jump_to_kingdom_list():
	for i in range(pages.size()):
		if pages[i]["type"] == "kingdom_list":
			current_page = i if i % 2 == 0 else i + 1
			display_current_page()
			return

func _on_sell_pressed(item: Dictionary):
	var index = PlayerStats.PlyrInv["Stock"].find(item)
	if index != -1 and ForgeBackend._add_for_sale(item["Name"], item["BaseVal"]):
		PlayerStats.PlyrInv["Stock"].pop_at(index)
		Ledger()

func _on_purchase_resources():
	ForgeBackend._purchase_res(100)
	Ledger()

func Ledger():
	generate_pages()
	current_page = min(current_page, pages.size() - 1)
	if current_page > 0 and current_page % 2 != 0:
		current_page += 1
	display_current_page()
