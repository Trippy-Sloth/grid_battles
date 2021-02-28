extends Node2D
class_name Player

const DEFAULT_NAME  = "Maximus"

var color
var designation
var units = []

signal turn_ended

func _init(_color: Color, _name: String = DEFAULT_NAME ):
	# self.set_process_input(false)
	self.color = _color
	self.designation = _name


func play_turn():
	set_process_input(true)
	for unit in self.units:
		unit.reset_properties()
	return self


func end_turn():
	set_process_input(false)
	emit_signal("turn_ended")


func check_for_turn_end():
	if not self._has_actions_left():
		self.end_turn()
		

func add_unit(unit: Unit):
	"""Adds an unit to this player for action execution.
	
	When adding an unit to a player we set the Player's team color on the unit,
	to differentiate teams in the map."""
	unit.set_color(color)
	unit.connect("unit_ready", self, "check_for_turn_end")
	self.units.append(unit)
	

func _actions_left() -> int:
	var actions = 0
	for unit in self.units:
		actions += unit.properties.actions_left()
	return actions


func _has_actions_left() -> bool:
	return self._actions_left() > 0
