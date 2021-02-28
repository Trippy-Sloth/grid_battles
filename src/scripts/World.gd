extends Node2D

enum ZINDEX {
	DEFAULT,
	OBSTACLES,
	UNITS
}

const NUM_PLAYERS = 2

var Legionarii = preload("res://scenes/units/Legionarii.tscn")
var Sagittarii = preload("res://scenes/units/Sagittarii.tscn")
var PlayerClass = load("res://scripts/players/ManualPlayer.gd")
var BattleResolver = load("res://scripts/BattleResolver.gd")
const COLORS = [Color.red, Color.blue]
const NAMES = ["Maximus", "Decius"]
var map
var state_manager
var battle_resolver

# Players configuration
var players = []

# UI components
# onready var grid_check = $ToolsGUI/Bar/TriggerGrid
onready var current_player_label = $GUI/Bar/CurrentPlayer
onready var end_turn_button = $GUI/Bar/EndTurn

func _ready():
	map = get_node("Map")
	state_manager = get_node("StateManager")
	battle_resolver = BattleResolver.new()
	var cells = map.initialize()
	
	# Mock player initialization. This will have to be changed. Currently 
	# we initialize the players and save them on the World. Units are 
	# instantiated randomly and associated to a random player.
	var new_player
	for i in range(NUM_PLAYERS):
		new_player = PlayerClass.new(COLORS[i], NAMES[i])
		
		# Connect handlers for action signals from players.
		# Trying to connect components through signals and actions so we
		# can abstract how players perform those actions. Some players might
		# may be player controlled, so respond to input events, other players
		# might be AI controlled.
		new_player.connect("select_unit", self, "select_unit")
		new_player.connect("move_unit", self, "move_unit")
		new_player.connect("hover", self, "hover")
		self.players.append(new_player)
		$TurnQueue.add_player(new_player)
	
	# Load all cells into state
	for hex in cells:
		state_manager.update_state(hex, null)
	
	_load_armies()
	
	# Start the game
	$TurnQueue.play_turn()
	
	# Setup UI. 
	# This will be placed manually on the scence, for better visuals.
	#grid_check.connect("pressed", self, "_toggle_grid")
	end_turn_button.connect("pressed", $TurnQueue, "ended_turn")


func _load_armies():
	var unit
	var state
	var unit_positions = [
		{
			"orientation": false,  # Facing Right
			"units": [
				{"type": Legionarii, "x": -2, "y": 0},
				{"type": Legionarii, "x": -2, "y": 1},
				{"type": Legionarii, "x": -2, "y": 2},
				{"type": Sagittarii, "x": -3, "y": 1},
				{"type": Sagittarii, "x": -3, "y": 2},
			]
		},
		{
			"orientation": true,  # Facing Left
			"units": [
				{"type": Legionarii, "x": 0, "y": -1},
				{"type": Legionarii, "x": 0, "y": 0},
				{"type": Legionarii, "x": 0, "y": 1},
			]
		}
	]
	
	for i in range(unit_positions.size()):
		for unit_data in unit_positions[i]["units"]:
			state = state_manager.get_state_by_coord(unit_data["x"], unit_data["y"])
			if state.hex and state.unit == null:
				unit = unit_data["type"].instance()
				unit.position = map.get_coordinates(state.hex)
				unit.z_index = ZINDEX.UNITS
				state.unit = unit
				self.players[i].add_unit(unit)
				add_child(unit)
				unit.face(unit_positions[i]["orientation"])


func _toggle_grid():
	# map.toggle_grid(grid_check.is_pressed())
	pass


func hover(pos: Vector2):
	map.hover(pos)


func move_unit(pos):
	var hex = map.get_hex(pos)
	if not hex:
		return
	
	var state = state_manager.get_state(hex)
	var active_state = state_manager.get_active_state()
	
	map.reset_movement_area()
	
	# Currently we can only move and attack. 
	# Check if cell is occupied and if unit is selected.
	if active_state.unit == null:
		return
	
	var target_pos = map.get_target(active_state.hex, hex, active_state.unit.properties.movement)
		
	# Now we can check if the target cell is occupied.
	# If it is and the cell's units is enemy we check if an attacks is possbile.
	# When possible we'll call the battle resolver for battle logic.
	# Also we might order the unit to enter "attack movement mode", that will
	# trigger an animation towards the target, the attack animation and then
	# return to its original place.
	if state.unit != null:
		if is_enemy(state.unit) and target_pos:
			var attacker: Unit = active_state.unit
			var defender: Unit = state.unit
			var distance = map.distance(active_state.hex, state.hex)
			if attacker.can_attack(distance):
				var result = battle_resolver.fight(attacker, defender, distance)
				attacker.attack(defender, distance, result)
				if result.outcome == Unit.BATTLE_OUTCOME.VICTORY:
					state_manager.update_state(hex, active_state.unit)
					state_manager.update_state(active_state.hex, null)
				elif result.outcome == Unit.BATTLE_OUTCOME.DEFEAT:
					state_manager.update_state(active_state.hex, null)
		state_manager.set_active_state(state)
		return 
	
	# There's no unit on the target cell so we can check if we're allowed to move.
	if target_pos:
		active_state.unit.move(target_pos, map.distance(active_state.hex, hex))
		state_manager.update_state(hex, active_state.unit)
		active_state.unit = null
	
	state_manager.set_active_state(state)


func finished_fighting():
	pass


func is_enemy(unit: Unit):
	"""Checks if the given unit is an enemy.
	
	An unit is an enemy when it's not associated with the current
	active player's units."""
	return not unit in $TurnQueue.active_player.units


func select_unit(pos):
	var hex = map.get_hex(pos)
	if not hex:
		return
	var state = state_manager.get_state(hex)
	
	# If there's an unit on the selected cell we set it as the selection
	# else we return to the initial state. Also the unit must belong the 
	# current selected player.
	if state.unit and state.unit in $TurnQueue.active_player.units:
		map.show_movement_area(hex, state.unit.properties.movement)
		state_manager.set_active_state(state)
	else:	
		state_manager.set_active_state(null)	
