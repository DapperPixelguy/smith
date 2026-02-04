extends Node

var _Weapons = {
	"Swords": {
		"Shortsword": {
			"Name": "Shortsword", "Metal": 5, "Wood": 1, "Coal": 2, "Time": 5, "BaseVal": 50,
			"BaseEdge": 10.0, "BaseStrength": 10.0, "BaseBalance": 10.0 # Balanced standard
		},
		"Broadsword": {
			"Name": "Broadsword", "Metal": 6, "Wood": 1, "Coal": 2, "Time": 6, "BaseVal": 60,
			"BaseEdge": 12.0, "BaseStrength": 13.0, "BaseBalance": 7.0 # Heavier, sharper, less balanced
		}
	},
	"Polearms": {
		"Spear": {
			"Name": "Spear", "Metal": 2, "Wood": 3, "Coal": 1, "Time": 4, "BaseVal": 50,
			"BaseEdge": 11.0, "BaseStrength": 6.0, "BaseBalance": 14.0 # High balance/reach, low durability
		},
		"Glaive": {
			"Name": "Glaive", "Metal": 3, "Wood": 3, "Coal": 1, "Time": 5, "BaseVal": 60,
			"BaseEdge": 14.0, "BaseStrength": 9.0, "BaseBalance": 9.0 # Aggressive cutting edge
		}
	},
	"Armour": {
		# Armour uses "Edge" as Deflection/Coverage for logic consistency
		"Breastplate": {
			"Name": "Breastplate", "Metal": 10, "Wood": 0, "Coal": 4, "Time": 8, "BaseVal": 90,
			"BaseEdge": 5.0, "BaseStrength": 20.0, "BaseBalance": 5.0 # Max Strength, low mobility
		},
		"Helmet": {
			"Name": "Helmet", "Metal": 7, "Wood": 0, "Coal": 3, "Time": 6, "BaseVal": 75,
			"BaseEdge": 8.0, "BaseStrength": 15.0, "BaseBalance": 10.0
		},
		"Gauntlets": {
			"Name": "Gauntlets", "Metal": 6, "Wood": 0, "Coal": 3, "Time": 6, "BaseVal": 70,
			"BaseEdge": 10.0, "BaseStrength": 10.0, "BaseBalance": 15.0 # High balance for movement
		},
		"Greaves": {
			"Name": "Greaves", "Metal": 8, "Wood": 0, "Coal": 4, "Time": 7, "BaseVal": 80,
			"BaseEdge": 7.0, "BaseStrength": 14.0, "BaseBalance": 12.0
		}
	}
}
