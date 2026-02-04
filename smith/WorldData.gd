extends Node

# --- DATA HUB ---
var Kingdom_List = {
	"Hralgorn": {
		"Strength": 9000, "Economic_Strength": 8000, "Maintenance_Cost": 450,
		"MiningCorps": {"Name": "Hralgorn Ironworks", "Export": "Fine Steel"},
		"Stability": 1.0, "Coords": Vector2(-500, -500), "AtWar": [], "Allies": [],
		"Lore": "The Holds of the North are renowned for their quality of steel, and the finesse of their smiths."
	},
	"Veridia": {
		"Strength": 7500, "Economic_Strength": 2500, "Maintenance_Cost": 100,
		"MiningCorps": {"Name": "Sanctorum Divers", "Export": "Obsidian"},
		"Stability": 1.0, "Coords": Vector2(-300, -300), "AtWar": [], "Allies": [],
		"Lore": "The Eastern Coastline is characterised by its many undersea volcanoes, with the Veridian Divers being experts at mining the Glass."
	},
	"New Karthus": {
		"Strength": 7500, "Economic_Strength": 5000, "Maintenance_Cost": 375,
		"MiningCorps": {"Name": "Karthusian Masons", "Export": "Granite"},
		"Stability": 1.0, "Coords": Vector2(-500, 0), "AtWar": [], "Allies": [],
		"Lore": "Despite a significant fall from grace, the New Karthuusian Empire has clawed their way back to economic prominence on the back of Slaves working in the vast quarries."
	},
	"Cirigras": {
		"Strength": 3500, "Economic_Strength": 1200, "Maintenance_Cost": 175,
		"MiningCorps": {"Name": "Ciri-Deep Excavations", "Export": "Obsidian"},
		"Stability": 0.3, "Coords": Vector2(-200, 0), "AtWar": [], "Allies": [],
		"Lore": "After their rebellion from Drenwyn, the Cirigras Governement took to mining the Volcanic Glass of the Grey Tide Mountainrange between them and Hralgorn."
	},
	"Drenwyn": {
		"Strength": 9000, "Economic_Strength": 7000, "Maintenance_Cost": 450,
		"MiningCorps": {"Name": "Drenwyn Timber-Guild", "Export": "Wood"},
		"Stability": 1.0, "Coords": Vector2(-500, 300), "AtWar": [], "Allies": [],
		"Lore": "Following the fall of their Imperialist ways due to an embarrassing loss to the Cirigrasian Rebels, the Drenwynians took to selling lumber to rebuild their economy."
	},
	"Khaeldos": {
		"Strength": 6000, "Economic_Strength": 3000, "Maintenance_Cost": 300,
		"MiningCorps": {"Name": "Khael-Steel Foundry", "Export": "Copper"},
		"Stability": 1.0, "Coords": Vector2(-200, 300), "AtWar": [], "Allies": [],
		"Lore": "In the floating isles of Khaeldros, very few metals are commonly found, except for the deceptively light copper deposits. While primarily used for ceremonial armours, some think the lightweightedness is best suited for blades."
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
		"Lore": "Ferroskar is the industrial titan of the Westerlands, the ."
	},
	"Vjellor": {
		"Strength": 4500, "Economic_Strength": 1500, "Maintenance_Cost": 225,
		"MiningCorps": {"Name": "Vjellor Sifters", "Export": "Bog Iron"},
		"Stability": 1.0, "Coords": Vector2(800, -500), "AtWar": [], "Allies": [],
		"Lore": "The isles of Vjellor are known for a single thing: their Hunts of the Leviathans. However, Leviathan Scale doesn't sell well on the international market, and so they resorted to selling their low-quality bog iron."
	},
	"Drosvarn": {
		"Strength": 5500, "Economic_Strength": 2500, "Maintenance_Cost": 275,
		"MiningCorps": {"Name": "Drosvarn Deep-Vein", "Export": "Grey Iron"},
		"Stability": 1.0, "Coords": Vector2(300, 0), "AtWar": [], "Allies": [],
		"Lore": "An isolationist Kingdom to the south of the Ferroskarian Mountains, known for the quality of their vanguard - not the quality of their metal."
	},
	"Zephyros": {
		"Strength": 3000, "Economic_Strength": 6000, "Maintenance_Cost": 150,
		"MiningCorps": {"Name": "Cloud-Peak Gems", "Export": "Zephyrosian Silver"},
		"Stability": 0.3, "Coords": Vector2(700, 0), "AtWar": [], "Allies": [],
		"Lore": "The Zephyrosian Clans are disjointed due to ideals, but their goals converge upon the matter of commerce. Zephyrosian Silver is one of the finer materilas in the realm, and fetches a fine price on the international market."
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
	TimeManager.week_ended.connect(_on_week_ended)

func _on_day_ended(_day_number):
	# Sequence of Logic: 
	# 1. Update Relations -> 2. Process Money/Stability -> 3. Resolve War Damage
	War.process_combat(Kingdom_List)

func _on_week_ended():
	Diplomacy.update_relations(Kingdom_List, Relations, DIPLOMATIC_ANCHORS)
	Economy.process_economics(Kingdom_List)

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
