extends Node

# --- DATA HUB ---
var Kingdom_List = {
	"Hralgorn": {
		"Strength": 9000, "Economic_Strength": 8000, "Maintenance_Cost": 450,
		"MiningCorps": {"Name": "Hralgorn Ironworks", "Export": "Fine Steel"},
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
		"MiningCorps": {"Name": "Ciri-Deep Excavations", "Export": "Obsidian"},
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
		"MiningCorps": {"Name": "Khael-Steel Foundry", "Export": "Copper"},
		"Stability": 1.0, "Coords": Vector2(-200, 300), "AtWar": [], "Allies": [],
		"Lore": "Militaristic state controlling copper."
	},
	"Dunsphyr": {
		"Strength": 4000, "Economic_Strength": 2000, "Maintenance_Cost": 200,
		"MiningCorps": {"Name": "Dunsphyr Deposits", "Export": "Grey Iron"},
		"Stability": 1.0, "Coords": Vector2(-500, 600), "AtWar": [], "Allies": [],
		"Lore": "Desert kingdom with flawed iron deposits."
	},
	"Ferroskar": {
		"Strength": 8500, "Economic_Strength": 9000, "Maintenance_Cost": 425,
		"MiningCorps": {"Name": "The Iron Vanguard", "Export": "Kingsteel"},
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
const DIPLOMATIC_ANCHORS = {
	"Cirigras": {"Drenwyn": 20.0, "Hralgorn": 95.0},
	"Hralgorn": {"Ferroskar": 90.0},
	"New Karthus": {"Khaeldos": 25.0},
}

# --- REFERENCES TO MANAGERS ---
# These are child nodes of this script
@onready var Economy = EconomyData
@onready var Diplomacy = RelationshipData
@onready var War = WarManager

func _ready():
	_Set_Initial_Relations()
	TimeManager.day_ended.connect(_on_day_ended)

func _on_day_ended(day_number):
	# Sequence of Logic: 
	# 1. Update Relations -> 2. Process Money/Stability -> 3. Resolve War Damage
	Diplomacy.update_relations(Kingdom_List, Relations, DIPLOMATIC_ANCHORS)
	Economy.process_economics(Kingdom_List)
	War.process_combat(Kingdom_List)

func _Set_Initial_Relations():
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

func get_current_price(material_name, kingdom_name):
	var base = MaterialData.MATERIALS[material_name]["base_price"]
	var k = Kingdom_List[kingdom_name]
	
	# Lore Logic: If a kingdom is unstable or at war, they charge more for exports!
	var stability_penalty = (1.0 - k["Stability"]) * 50.0
	var war_tax = 1.5 if k["AtWar"].size() > 0 else 1.0
	
	return (base + stability_penalty) * war_tax
