extends Node
# MaterialData.gd

const MATERIALS = {
	"Metals": {
		"Obsidian": {
			"edge": 1.5, "strength": 0.4, "balance": 0.8,
			"base_price": 120, "color": Color("#4a004a")
		},
		"Copper": {
			"edge": 0.7, "strength": 0.6, "balance": 1.4,
			"base_price": 40, "color": Color("#b87333")
		},
		"Fine Steel": {
			"edge": 1.1, "strength": 1.1, "balance": 1.1,
			"base_price": 80, "color": Color("#b0c4de")
		},
		"Kingsteel": {
			"edge": 1.3, "strength": 1.3, "balance": 1.3,
			"base_price": 250, "color": Color("#e0ffff")
		},
		"Zephyrosian Silver": {
			"edge": 1.2, "strength": 0.8, "balance": 1.2,
			"base_price": 180, "color": Color("#c0c0c0")
		},
		"Grey Iron": {
			"edge": 0.8, "strength": 0.8, "balance": 0.8,
			"base_price": 30, "color": Color("#808080")
		},
		"Bog Iron": {
			"edge": 0.5, "strength": 0.4, "balance": 0.6,
			"base_price": 10, "color": Color("#4b3621")
		},
	},
	"Granite": {"base_price": 20, "color": Color("5e5e5eff")},
	"Wood": {"base_price": 20, "color": Color("3d2611ff")},
	"Coal": {"base_price": 20, "color": Color("000000ff")}
}

func get_stat_modifier(material_name: String) -> Dictionary:
	# 1. Check if it's a Top-Level resource (Wood, Granite, Coal)
	if MATERIALS.has(material_name):
		return MATERIALS[material_name]
	
	# 2. Check inside the Metals sub-dictionary
	if MATERIALS["Metals"].has(material_name):
		return MATERIALS["Metals"][material_name]
	
	# 3. Handle partial matches (like "Hralgorn Fine Steel")
	for metal_key in MATERIALS["Metals"].keys():
		if metal_key in material_name:
			return MATERIALS["Metals"][metal_key]
			
	return {"edge": 1.0, "strength": 1.0, "balance": 1.0, "base_price": 0}
