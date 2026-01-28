extends Node

# This script handles Maintenance, Stability, Rebuilding, and Strength Caps.

func process_economics(kingdoms):
	for name in kingdoms.keys():
		var k = kingdoms[name]
		
		# 1. VASSAL REBUILDING AID
		_handle_vassal_logic(name, k, kingdoms)
		
		# 2. CALCULATE COSTS
		# Every 1000 Strength points adds 50 to base maintenance (Bloat Tax)
		var army_bloat_tax = (k["Strength"] / 1000.0) * 50.0 
		var total_maintenance = k["Maintenance_Cost"] + army_bloat_tax
		
		# 3. NET INCOME & STABILITY
		var net_income = k["Economic_Strength"] - total_maintenance
		
		if net_income < 0: 
			k["Stability"] -= 0.03 # Financial strain hurts the nation
		else: 
			k["Stability"] += 0.01 # Prosperity helps
		
		# Passive peace-time recovery for fallen nations
		if k["AtWar"].size() == 0 and k["Stability"] < 0.2:
			k["Stability"] += 0.005
			
		k["Stability"] = clamp(k["Stability"], 0.0, 1.0)
		
		# 4. STRENGTH RECOVERY & PLATEAU (Peace Time only)
		if k["AtWar"].size() == 0:
			_handle_strength_plateau(k, net_income)

func _handle_vassal_logic(vassal_name, k, kingdoms):
	if k.has("VassalOf") and k["VassalOf"] != "":
		var overlord_name = k["VassalOf"]
		if kingdoms.has(overlord_name):
			var overlord = kingdoms[overlord_name]
			
			# Overlord pays to rebuild the vassal
			var aid = 50.0
			overlord["Economic_Strength"] -= aid
			k["Economic_Strength"] += aid
			
			# Call back to Diplomacy/War for Independence checks
			get_parent().War.check_for_independence(vassal_name, overlord_name, kingdoms)

func _handle_strength_plateau(k, net_income):
	if net_income > 0:
		# If below Economic Strength, grow based on Stability
		if k["Strength"] < k["Economic_Strength"]:
			if k["Stability"] > 0.8: k["Strength"] += 40
			elif k["Stability"] < 0.4: k["Strength"] -= 20
		else:
			# Soft Cap: Drift back toward the Economic Limit
			k["Strength"] = lerp(float(k["Strength"]), float(k["Economic_Strength"]), 0.1)
	else:
		# Bankruptcy: Troops desert if they aren't paid
		k["Strength"] -= 50.0 * (1.0 - k["Stability"])
	
	k["Strength"] = max(0, k["Strength"])
