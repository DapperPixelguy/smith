extends Node

var Kingdom_List = {
	# --- WESTERN CONTINENT ---
	"Hralgorn": {
		"Strength": 9000, "Economic_Strength": 8000, "Maintenance_Cost": 450,
		"MiningCorps": {"Name": "Hralgorn Ironworks", "Export": "Hralgorn Fine Steel"},
		"Stability": 1.0, "Coords": Vector2(-500, -500), "AtWar": [], "Allies": [],
		"Lore": "Military Supremacy over Mortheim through Fine Steel."
	},
	"Veridia": {
		"Strength": 7500, "Economic_Strength": 2500, "Maintenance_Cost": 100,
		"MiningCorps": {"Name": "Sanctorum Divers", "Export": "Obsidian"},
		"Stability": 1.0, "Coords": Vector2(-300, -300), "AtWar": [], "Allies": [],
		"Lore": "Southern valley miners."
	},
	"New Karthus": {
		"Strength": 7500, "Economic_Strength": 5000, "Maintenance_Cost": 375,
		"MiningCorps": {"Name": "Karthusian Masons", "Export": "Granite"},
		"Stability": 1.0, "Coords": Vector2(-500, 0), "AtWar": [], "Allies": [],
		"Lore": "An empire attempting to claw back power."
	},
	"Cirigras": {
		"Strength": 3500, "Economic_Strength": 1200, "Maintenance_Cost": 175,
		"MiningCorps": {"Name": "Ciri-Deep Excavations", "Export": "Cirgrasian Obsidian"},
		"Stability": 0.3, "Coords": Vector2(-200, 0), "AtWar": [], "Allies": [],
		"Lore": "Holders of the Volcanic Mountainside; forge brittle weapons."
	},
	"Drenwyn": {
		"Strength": 9000, "Economic_Strength": 7000, "Maintenance_Cost": 450,
		"MiningCorps": {"Name": "Drenwyn Timber-Guild", "Export": "Wood"},
		"Stability": 1.0, "Coords": Vector2(-500, 300), "AtWar": [], "Allies": [],
		"Lore": "Imperialists who lost their mountainside to Cirigras."
	},
	"Khaeldos": {
		"Strength": 6000, "Economic_Strength": 3000, "Maintenance_Cost": 300,
		"MiningCorps": {"Name": "Khael-Steel Foundry", "Export": "Khaeldrosi Copper"},
		"Stability": 1.0, "Coords": Vector2(-200, 300), "AtWar": [], "Allies": [],
		"Lore": "Militaristic state controlling copper."
	},
	"Dunsphyr": {
		"Strength": 4000, "Economic_Strength": 2000, "Maintenance_Cost": 200,
		"MiningCorps": {"Name": "Dunsphyr Deposits", "Export": "Grey Iron"},
		"Stability": 1.0, "Coords": Vector2(-500, 600), "AtWar": [], "Allies": [],
		"Lore": "Desert kingdom with flawed iron deposits."
	},

	# --- EASTERN CONTINENT ---
	"Ferroskar": {
		"Strength": 8500, "Economic_Strength": 9000, "Maintenance_Cost": 425,
		"MiningCorps": {"Name": "The Iron Vanguard", "Export": "Kingsteel (Ferroskar)"},
		"Stability": 1.0, "Coords": Vector2(500, -500), "AtWar": [], "Allies": [],
		"Lore": "Industrial titan of the East."
	},
	"Vjellor": {
		"Strength": 4500, "Economic_Strength": 1500, "Maintenance_Cost": 225,
		"MiningCorps": {"Name": "Vjellor Sifters", "Export": "Bog Iron"},
		"Stability": 1.0, "Coords": Vector2(800, -500), "AtWar": [], "Allies": [],
		"Lore": "Islanders exporting low-quality Bog Iron."
	},
	"Drosvarn": {
		"Strength": 5500, "Economic_Strength": 2500, "Maintenance_Cost": 275,
		"MiningCorps": {"Name": "Drosvarn Deep-Vein", "Export": "Grey Iron"},
		"Stability": 1.0, "Coords": Vector2(300, 0), "AtWar": [], "Allies": [],
		"Lore": "Southern valley neighbors to Ferroskar."
	},
	"Zephyros": {
		"Strength": 3000, "Economic_Strength": 6000, "Maintenance_Cost": 150,
		"MiningCorps": {"Name": "Cloud-Peak Gems", "Export": "Zephyrosian Silver"},
		"Stability": 0.3, "Coords": Vector2(700, 0), "AtWar": [], "Allies": [],
		"Lore": "Disjointed clans exporting silver."
	}
}

var Relations = {} 
var Weekly_Trade_Volume = {}
var Hostility_Weeks = {}

const DIPLOMATIC_ANCHORS = {
	"Cirigras": {"Drenwyn": 5.0, "Hralgorn": 95.0},
	"Hralgorn": {"Ferroskar": 90.0},
	"New Karthus": {"Khaeldos": 25.0}
}

func _ready():
	TimeManager.day_ended.connect(_process_world_tick)
	TimeManager.day_ended.connect(_Update_Global_Diplomacy)
	_Set_Relations()
	_Refresh_Alliances()

func _process_world_tick(_day_number):
	for name in Kingdom_List.keys():
		var k = Kingdom_List[name]
		
		# --- 1. DYNAMIC MAINTENANCE ---
		# Every 1000 Strength points now costs an additional % of the base maintenance.
		# This prevents "Infinite Armies" for poor kingdoms.
		var army_bloat_tax = (k["Strength"] / 1000.0) * 50.0 
		var total_maintenance = k["Maintenance_Cost"] + army_bloat_tax
		
		# --- 2. ECONOMY & STABILITY ---
		var net_income = k["Economic_Strength"] - total_maintenance
		if net_income < 0: 
			k["Stability"] -= 0.03 # Financial strain hurts the nation
		else: 
			k["Stability"] += 0.01
		
		k["Stability"] = clamp(k["Stability"], 0.0, 1.0)
		
		# --- 3. CAPPED STRENGTH RECOVERY ---
		var enemy_count = k["AtWar"].size()
		if enemy_count > 0:
			var stability_modifier = 2.0 - (k["Stability"] * 1.5)
			var base_attrition = 100.0 * stability_modifier
			k["Strength"] -= base_attrition * enemy_count
			
			# War also drains stability now
			k["Stability"] -= 0.005 * enemy_count 
		else:
			# Soft Cap: Recovery slows down as Strength nears Economic_Strength
			if k["Strength"] < k["Economic_Strength"]:
				if k["Stability"] > 0.8: k["Strength"] += 40
				elif k["Stability"] < 0.4: k["Strength"] -= 20
			else:
				# Maintenance is too high to grow further; the army "plateaus"
				k["Strength"] = lerp(k["Strength"], float(k["Economic_Strength"]), 0.1)
		
		k["Strength"] = max(0, k["Strength"])
		if k["Strength"] <= 0 and enemy_count > 0:
			_handle_kingdom_defeat(name)

func _Update_Global_Diplomacy(_day_number):
	for k1_name in Kingdom_List.keys():
		var k1 = Kingdom_List[k1_name]	
		for k2_name in Kingdom_List.keys():
			if k1_name == k2_name: continue
			
			var current_rel = Relations[k1_name][k2_name]
			var change = 0.0
			var dist = k1["Coords"].distance_to(Kingdom_List[k2_name]["Coords"])
			
			if dist < 400: change -= 0.5
			
			# Shared Enemies Bonus
			for enemy in k1["AtWar"]:
				if enemy in Kingdom_List[k2_name]["AtWar"]: change += 2.0
			
			# Lore Drift
			var target = 50.0
			if DIPLOMATIC_ANCHORS.has(k1_name) and DIPLOMATIC_ANCHORS[k1_name].has(k2_name):
				target = DIPLOMATIC_ANCHORS[k1_name][k2_name]
			elif DIPLOMATIC_ANCHORS.has(k2_name) and DIPLOMATIC_ANCHORS[k2_name].has(k1_name):
				target = DIPLOMATIC_ANCHORS[k2_name][k1_name]
			
			if current_rel > target: change -= 0.1
			elif current_rel < target: change += 0.1
			
			Relations[k1_name][k2_name] = clamp(current_rel + change, 0.0, 100.0)

	_Refresh_Alliances()
	_Check_For_Conflict_Triggers()

func _Refresh_Alliances():
	for k1_name in Kingdom_List.keys():
		for k2_name in Kingdom_List.keys():
			if k1_name == k2_name: continue
			
			var rel = Relations[k1_name][k2_name]
			var k1_allies = Kingdom_List[k1_name]["Allies"]
			var k2_allies = Kingdom_List[k2_name]["Allies"]
			
			if rel >= 80.0:
				if not k2_name in k1_allies: k1_allies.append(k2_name)
				if not k1_name in k2_allies: k2_allies.append(k1_name)
			elif rel < 60.0:
				if k2_name in k1_allies: k1_allies.erase(k2_name)
				if k1_name in k2_allies: k2_allies.erase(k1_name)

func _Check_For_Conflict_Triggers():
	for k1_name in Kingdom_List.keys():
		var k1 = Kingdom_List[k1_name]
		if k1["AtWar"].size() > 0: continue # Peaceful kingdoms initiate wars
		
		for k2_name in Relations[k1_name].keys():
			if Relations[k1_name][k2_name] <= 5.0:
				var k2 = Kingdom_List[k2_name]
				var strength_ratio = k1["Strength"] / max(1.0, k2["Strength"])
				
				# Only attack if they have a chance (Posture Check)
				if strength_ratio > 0.5 or k1["Stability"] > 0.8:
					_declare_war(k1_name, k2_name)

func _declare_war(aggressor: String, defender: String):
	_add_to_war(aggressor, defender)
	print("WAR DECLARED: ", aggressor, " vs ", defender)
	
	# CALL TO ARMS: Defender asks their allies for help
	for ally in Kingdom_List[defender]["Allies"]:
		# Ensure the ally doesn't also like the aggressor
		if not aggressor in Kingdom_List[ally]["Allies"]:
			_add_to_war(ally, aggressor)
			print("DEFENSIVE PACT: ", ally, " joins to protect ", defender)

func _add_to_war(a: String, b: String):
	# Forces the relationship to be mutual so nobody "recovers" during war
	if !b in Kingdom_List[a]["AtWar"]: Kingdom_List[a]["AtWar"].append(b)
	if !a in Kingdom_List[b]["AtWar"]: Kingdom_List[b]["AtWar"].append(a)

func _handle_kingdom_defeat(k_name: String):
	print("DEFEAT: ", k_name, " has been neutralized.")
	# Remove this kingdom from all enemy lists
	for opponent in Kingdom_List[k_name]["AtWar"]:
		Kingdom_List[opponent]["AtWar"].erase(k_name)
	
	Kingdom_List[k_name]["AtWar"].clear()
	Kingdom_List[k_name]["Stability"] = 0.05
	Kingdom_List[k_name]["Strength"] = 0

func _Set_Relations():
	for k1 in Kingdom_List.keys():
		Relations[k1] = {}
		for k2 in Kingdom_List.keys():
			if k1 == k2: continue
			var base = 50.0
			if DIPLOMATIC_ANCHORS.has(k1) and DIPLOMATIC_ANCHORS[k1].has(k2):
				base = DIPLOMATIC_ANCHORS[k1][k2]
			elif DIPLOMATIC_ANCHORS.has(k2) and DIPLOMATIC_ANCHORS[k2].has(k1):
				base = DIPLOMATIC_ANCHORS[k2][k1]
			Relations[k1][k2] = base
