extends Reference

const INITIATIVE_BUFF := 0.2  # Adds 20% damage due to initiative


func preview(attacker: Unit, defender: Unit, distance: int = 1):
	pass


func fight(attacker: Unit, defender: Unit, distance: int = 1):
	"""Calculates the outcome of a fight between units.
	
	This method will inform both units of any stats changes.
	Currently these stats changes are only referring to armor and 
	health.
	
	In the near future we can implement an Experience system, adding veterancy.
	"""
	# Try to perform all checks needed fo a battle to be resolved, including
	# checking if this battle is even possible.
	if not attacker.can_attack(distance):
		push_error("Unit cannot attack at " + str(distance))
	
	# The attack value will be the unit's attack (or ranged attack) with an
	# added modifier due to initiative.
	var attacker_attack = (
		attacker.attack if distance == Unit.MELEE_DISTANCE else attacker.ranged_attack
	) * (1 + INITIATIVE_BUFF)  # hmmm, should there be initiative?
	
	# Hmmm, messing directly with the unit's stats is not cool. Reimplement this
	# by informing the unit of the given damage, and letting it decide what to do.
	# Update the defender's health according to the given damage
	var damage = max(0, attacker_attack - defender.properties.defense)
	
	print("==== Battle Report =====")
	print("Atacker gave " + str(attacker_attack) + " damage points to defender")
	print("Defender received " + str(damage) + " of damage (Absorbed " + str(defender.properties.defense) + ").")
	
	# The default batte outcome is a draw
	var outcome = Unit.BATTLE_OUTCOME.DRAW
	
	var retaliation_damage = 0
	
	# If it was a melee attack and the defender is not dead it has an 
	# opportunity for retaliation.
	if defender.properties.health - damage > 0:
		if distance == Unit.MELEE_DISTANCE:
			retaliation_damage = max(0, defender.attack - attacker.properties.defense)
			
			# A sacrifice has been made. The attacker has died.
			if attacker.properties.health - retaliation_damage <= 0:
				outcome = Unit.BATTLE_OUTCOME.DEFEAT
	else:
		outcome = Unit.BATTLE_OUTCOME.VICTORY
	
	return Battle.new(retaliation_damage, damage, outcome)
