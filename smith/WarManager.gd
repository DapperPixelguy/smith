extends Node

# This script handles Combat Attrition, Conquest, and Independence Wars.

func process_combat(kingdoms):
	for name in kingdoms.keys():
		var k = kingdoms[name]
		var enemies = k["AtWar"]
		
		if enemies.size() > 0:
			var stability_modifier = 2.0 - (k["Stability"] * 1.5)
			var total_incoming_damage = 0.0
			
			for enemy_name in enemies:
				var damage = 100.0 * stability_modifier
				
				# ALLY SUPPORT: Stronger allies absorb 40% of the pressure
				for ally_name in k["Allies"]:
					var ally = kingdoms[ally_name]
					if enemy_name in ally["AtWar"] and ally["Strength"] > k["Strength"]:
						damage *= 0.6
						break 
							
				total_incoming_damage += damage
			
			k["Strength"] -= total_incoming_damage
			k["Stability"] -= 0.005 * enemies.size() # War fatigue
			
			# Check for defeat
			if k["Strength"] <= 0:
				_handle_kingdom_defeat(name, kingdoms)

func declare_war(aggressor: String, defender: String, kingdoms: Dictionary):
	_add_to_war(aggressor, defender, kingdoms)
	print("WAR: ", aggressor, " vs ", defender)
	
	# Call to Arms
	for ally in kingdoms[defender]["Allies"]:
		if not aggressor in kingdoms[ally]["Allies"]:
			_add_to_war(ally, aggressor, kingdoms)
			print("ALLIANCE PACT: ", ally, " joins to protect ", defender)

func _add_to_war(a: String, b: String, kingdoms: Dictionary):
	if !b in kingdoms[a]["AtWar"]: kingdoms[a]["AtWar"].append(b)
	if !a in kingdoms[b]["AtWar"]: kingdoms[b]["AtWar"].append(a)

func _handle_kingdom_defeat(k_name: String, kingdoms: Dictionary):
	print("DEFEAT: ", k_name, " has fallen.")
	
	var loser_econ = kingdoms[k_name]["Economic_Strength"]
	var opponents = kingdoms[k_name]["AtWar"].duplicate()
	
	if opponents.size() > 0:
		# Spoils of War: Winners take 50% of the economy
		var share = (loser_econ * 0.5) / opponents.size()
		for opponent in opponents:
			kingdoms[opponent]["Economic_Strength"] += share
			kingdoms[opponent]["AtWar"].erase(k_name)
			
			# VASSALIZATION: The first opponent in the list becomes the Overlord
			if opponent == opponents[0]:
				kingdoms[k_name]["VassalOf"] = opponent
				print(k_name, " is now a vassal of ", opponent)

	kingdoms[k_name]["AtWar"].clear()
	kingdoms[k_name]["Stability"] = 0.05
	kingdoms[k_name]["Strength"] = 0
	kingdoms[k_name]["Economic_Strength"] = loser_econ * 0.1

func check_for_independence(vassal_name, overlord_name, kingdoms):
	var k = kingdoms[vassal_name]
	var overlord = kingdoms[overlord_name]
	
	# SPONSORSHIP CHECK (Proxy Strength)
	# You can call a function in DiplomacyManager here if you want 
	# relations to affect secret strength boosts.
	
	# Rebellion Trigger
	if k["Strength"] > (overlord["Strength"] * 0.4) and k["Stability"] > 0.6:
		_initiate_rebellion(vassal_name, overlord_name, kingdoms)

func _initiate_rebellion(vassal_name, overlord_name, kingdoms):
	print("!!! REBELLION !!! ", vassal_name, " rises against ", overlord_name)
	kingdoms[vassal_name]["VassalOf"] = "" 
	declare_war(vassal_name, overlord_name, kingdoms)
