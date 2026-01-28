extends Node
# MaterialData.gd

const MATERIALS = {
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
	}
}

func get_stat_modifier(material_name: String) -> Dictionary:
	# This helper function allows your weapon generator to pull data safely
	for key in MATERIALS.keys():
		if key in material_name: # Matches "Hralgorn Fine Steel" to "Fine Steel"
			return MATERIALS[key]
	return {"edge": 1.0, "strength": 1.0, "balance": 1.0} # Default fallback
