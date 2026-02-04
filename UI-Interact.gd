extends Node

# Ledger system tracking
var current_page = 0
var pages = []
const ITEMS_PER_PAGE = 10

func _ready():
	TimeManager.day_ended.connect(TickUpdated)
	TimeManager.tick_updated.connect(Ledger)
	
	# Connect directly to the scroll containers
	$LedgerPage/LeftPageScroll.gui_input.connect(_on_left_page_clicked)
	$LedgerPage/RightPageScroll.gui_input.connect(_on_right_page_clicked)

	$LedgerPage/LeftPageScroll.mouse_filter = Control.MOUSE_FILTER_PASS
	$LedgerPage/RightPageScroll.mouse_filter = Control.MOUSE_FILTER_PASS
		
	_create_ledger_navigation()
	generate_pages()
	display_current_page()

# --- NAVIGATION ---

func _on_left_page_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_prev_page()

func _on_right_page_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_next_page()

func _on_prev_page():
	if current_page <= 2:
		current_page = 0
	else:
		current_page -= 2
	display_current_page()

func _on_next_page():
	if current_page == 0:
		current_page = 2 
	elif current_page + 1 < pages.size():
		current_page += 2 
	display_current_page()

func _jump_to_kingdom(kingdom_name: String):
	for i in range(pages.size()):
		if pages[i].get("type") == "kingdom_detail" and pages[i].get("kingdom_name") == kingdom_name:
			current_page = i if i % 2 == 0 else i + 1
			display_current_page()
			return

func _jump_to_kingdom_list():
	for i in range(pages.size()):
		if pages[i]["type"] == "kingdom_list":
			current_page = i if i % 2 == 0 else i + 1
			display_current_page()
			return

# --- DATA GENERATION ---

func generate_pages():
	pages.clear()
	pages.append({"type": "player_stats"})
	
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

# --- RENDERING ---

func display_current_page():
	clear_page_display()
	
	if current_page == 0:
		show_blank_page($LedgerPage/LeftPageScroll/LeftPage)
		display_page_content($LedgerPage/RightPageScroll/RightPage, pages[0])
	else:
		if (current_page - 1) < pages.size():
			display_page_content($LedgerPage/LeftPageScroll/LeftPage, pages[current_page - 1])
		else:
			show_blank_page($LedgerPage/LeftPageScroll/LeftPage)
			
		if current_page < pages.size():
			display_page_content($LedgerPage/RightPageScroll/RightPage, pages[current_page])
		else:
			show_blank_page($LedgerPage/RightPageScroll/RightPage)
	
	_update_page_counter()

func display_page_content(container, page_data):
	match page_data["type"]:
		"player_stats": show_player_stats(container)
		"stock": show_stock_page(container, page_data["start_index"], page_data["end_index"])
		"apprentice": show_apprentice_page(container)
		"resources": show_resources_page(container)
		"kingdom_list": show_kingdom_list(container)
		"kingdom_detail": show_kingdom_detail(container, page_data["kingdom_name"])

func show_player_stats(container):
	var stats_label = Label.new()
	stats_label.add_theme_color_override("font_color", Color.BLACK)
	stats_label.text = "=== PLAYER STATS ===\n"
	stats_label.text += "XP: " + str(PlayerStats.PlyrStats["PlyrXp"]) + "\n"
	stats_label.text += "Shillings: " + str(PlayerStats.PlyrInv["Shillings"]) + "\n"
	container.add_child(stats_label)

func show_stock_page(container, start_idx: int, end_idx: int):
	for i in range(start_idx, end_idx):
		var item = PlayerStats.PlyrInv["Stock"][i]
		var btn = Button.new()
		btn.text = item["Name"] + " (" + str(item["BaseVal"]) + "s)"
		btn.pressed.connect(_on_sell_pressed.bind(item))
		container.add_child(btn)

func show_apprentice_page(container):
	var title = Label.new()
	title.text = "=== WORKFORCE ==="
	title.add_theme_color_override("font_color", Color.BLACK)
	container.add_child(title)
	var staff = Label.new()
	var apprentices = PlayerStats.PlyrInv.get("Apprentices", [])
	staff.text = "Active: " + str(apprentices.size())
	container.add_child(staff)

func show_resources_page(container):
	var title = Label.new()
	title.text = "=== RESOURCES ==="
	title.add_theme_color_override("font_color", Color.BLACK)
	container.add_child(title)
	var inv = PlayerStats.PlyrInv
	var res = Label.new()
	res.text = "Coal: " + str(inv.get("Coal", 0)) + "\nIron: " + str(inv["Metals"].get("Grey Iron", 0))
	container.add_child(res)

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
	var lore = Label.new()
	lore.text = kingdom.get("Lore", "")
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore.custom_minimum_size.x = 180
	container.add_child(lore)
	var back_btn = Button.new()
	back_btn.text = "Back to List"
	back_btn.pressed.connect(_jump_to_kingdom_list)
	container.add_child(back_btn)

# --- HELPERS ---

func _create_ledger_navigation():
	var page_counter = Label.new()
	page_counter.name = "PageCounter"
	page_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$LedgerPage.add_child(page_counter)

func _update_page_counter():
	var counter = $LedgerPage.get_node("PageCounter")
	counter.text = "Cover" if current_page == 0 else "Pages " + str(current_page) + "-" + str(current_page + 1)

func clear_page_display():
	for child in $LedgerPage/LeftPageScroll/LeftPage.get_children(): child.queue_free()
	for child in $LedgerPage/RightPageScroll/RightPage.get_children(): child.queue_free()

func show_blank_page(container):
	container.add_child(Label.new())

func _on_sell_pressed(item: Dictionary):
	var index = PlayerStats.PlyrInv["Stock"].find(item)
	if index != -1:
		if ForgeBackend._add_for_sale(item, item["BaseVal"]):
			PlayerStats.PlyrInv["Stock"].pop_at(index)
			Ledger()

func Ledger():
	generate_pages()
	current_page = min(current_page, pages.size() - 1)
	if current_page > 0 and current_page % 2 != 0: current_page += 1
	display_current_page()

func TickUpdated():
	return 0
