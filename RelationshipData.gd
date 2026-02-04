extends Node

# This script handles Relation Drift, Alliances, and War Triggers.

func update_relations(kingdoms, relations, anchors):
	_apply_diplomatic_drift(kingdoms, relations, anchors)
	_refresh_alliances(kingdoms, relations)
	_check_for_conflict_triggers(kingdoms, relations)

func _apply_diplomatic_drift(kingdoms, relations, anchors):
	for k1_name in kingdoms.keys():
		var k1 = kingdoms[k1_name]
		for k2_name in kingdoms.keys():
			if k1_name == k2_name: continue
			
			var current_rel = relations[k1_name][k2_name]
			var change = 0.0
			
			# 1. Proximity Tension (Neighbors are naturally suspicious)
			var dist = k1["Coords"].distance_to(kingdoms[k2_name]["Coords"])
			if dist < 400: change -= 0.5
			
			# 2. Shared Enemies Bonus (The enemy of my enemy is my friend)
			for enemy in k1["AtWar"]:
				if enemy in kingdoms[k2_name]["AtWar"]: 
					change += 2.0
			
			# 3. Lore Drift (Relations naturally pull toward their DIPLOMATIC_ANCHORS)
			var target = 50.0
			if anchors.has(k1_name) and anchors[k1_name].has(k2_name):
				target = anchors[k1_name][k2_name]
			elif anchors.has(k2_name) and anchors[k2_name].has(k1_name):
				target = anchors[k2_name][k1_name]
			
			if current_rel > target: change -= 0.1
			elif current_rel < target: change += 0.1
			
			# 4. Peace Dividend (If both are at peace, relations slowly heal)
			if k1["AtWar"].size() == 0 and kingdoms[k2_name]["AtWar"].size() == 0:
				if current_rel < 50: change += 0.05
			
			relations[k1_name][k2_name] = clamp(current_rel + change, 0.0, 100.0)

func _refresh_alliances(kingdoms, relations):
	for k1_name in kingdoms.keys():
		for k2_name in kingdoms.keys():
			if k1_name == k2_name: continue
			
			var rel = relations[k1_name][k2_name]
			var k1_allies = kingdoms[k1_name]["Allies"]
			var k2_allies = kingdoms[k2_name]["Allies"]
			
			# Form Alliance at 80+
			if rel >= 80.0:
				if not k2_name in k1_allies: k1_allies.append(k2_name)
				if not k1_name in k2_allies: k2_allies.append(k1_name)
			# Break Alliance below 60
			elif rel < 60.0:
				if k2_name in k1_allies: k1_allies.erase(k2_name)
				if k1_name in k1_allies: k1_allies.erase(k2_name) # Double check cleanup

func _check_for_conflict_triggers(kingdoms, relations):
	# Staggered logic to prevent everyone declaring war on the same tick
	var names = kingdoms.keys()
	names.shuffle()
	var initiator_name = names[0]
	var k1 = kingdoms[initiator_name]
	
	# Only peaceful, stable kingdoms with manageable wars start new ones
	if k1["AtWar"].size() < 2 and k1["Stability"] > 0.4:
		for target_name in relations[initiator_name].keys():
			if relations[initiator_name][target_name] <= 5.0:
				# 10% chance to actually declare war today if threshold is met
				if randf() < 0.1:
					var k2 = kingdoms[target_name]
					var strength_ratio = k1["Strength"] / max(1.0, k2["Strength"])
					
					# Only attack if they aren't suicide-charging a giant
					if strength_ratio > 0.5:
						get_parent().War.declare_war(initiator_name, target_name, kingdoms)
						break
