extends Node

class_name StateManager

enum STATES {
	INITIAL,
	MOVING,
	SELECTED	
}


class State:
	var hex: Hex
	var unit: Node2D
	
	func _init(_hex: Hex = null, _unit: Node2D = null):
		self.hex = _hex
		self.unit = _unit
	
var selection = State.new()

# The state of the world.
# TODO: This state can be loaded from file or another persistent resource type.
var map = {}


func update_state(hex: Hex, unit: Node2D):
	map[self._get_identifier(hex.x, hex.y)] = State.new(hex, unit)


func get_state(hex: Hex):
	return map[_get_identifier(hex.x, hex.y)]


func get_state_by_coord(x: int, y: int):
	return map[_get_identifier(x, y)]


func get_active_state():
	return selection
	

func set_active_state(state: State):
	selection = State.new() if not state else state


func _get_identifier(x: int, y: int):
	return ("%s%s" % [x, y]).sha256_text()
