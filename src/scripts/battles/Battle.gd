extends Reference

class_name Battle


var attacker = {"damage": 0}
var defender = {"damage": 0}
var outcome


func _init(attacker_damage: float, defender_damage: float, _outcome: int):
	self.attacker["damage"] = attacker_damage
	self.defender["damage"] = defender_damage
	self.outcome = _outcome

