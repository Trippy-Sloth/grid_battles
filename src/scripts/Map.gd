"""
This object is responsible for everything regarding the map, including drawing the Grid
storing the object's positions on cells and checks like the ability to move or returning the 
object stored at a certain cell.
"""
extends Node2D

# Scenes and scripts imports
var Grid = load("res://scripts/Grid.gd")
var Leg = preload("res://scenes/Legionarii.tscn")

export(Vector2) var cell_size = Vector2(45, 55)

# The number of cells for each grid axis, x and y. 
# Grid total size is (grid_cell_number + 1)^2 - grid_cell_number * 2
export(int) var grid_cell_number = 10

# Allow changing the grid mode on editor
enum MODES {
	FLAT,
	POINTY
}
export(MODES) var mode = MODES.FLAT

# Allow changing the grid's layout from the editor.
enum LAYOUT {
	HEXAGON,
	RECT
}
export(LAYOUT) var layout = LAYOUT.HEXAGON

enum ZINDEX {
	DEFAULT,
	OBSTACLES,
	UNITS
}

# Unit types are preload for instancing
var Map = load("res://scripts/Map.gd")

enum STATES {
	INITIAL,
	MOVING,
	SELECTED	
}


# Create a class to define a schema for selection data storage.
# Y U CREATE CLASES?!?
class Selection:
	var state = STATES.INITIAL
	var cell = null
	
var selection = Selection.new()

# This will store all highlights, so we can remove them at will
var movement_highlights = []

# This object will be used to display the selected cell on the map.
var selector: Polygon2D

# The origin point of the grid. Dependending on the type of grid the origin will 
# define from where it expands. Remember that HEXAGON grids exapand in circles
# outwards, while RECT grids expand to the right and down.
# The default value will be the center of the viewport.
export(Vector2) var origin

# Reference to the Grid class
var grid

# The state of the world.
# TODO: This state can be loaded from file or another persistent resource type.
var map = {}


func _ready():	
	randomize()
	origin = get_viewport_rect().size / 2 if not origin else origin
	grid = Grid.new(mode, cell_size, origin)
	grid.generate(grid_cell_number, layout)
	
	# Draw cells and populate map
	for hex in grid.cells:		
		_draw_hex(hex)
		map[_get_identifier(hex.x, hex.y)] = {
			"hex": hex,
			"unit": _add_unit(hex, $UnitsDisplay)
		}	


func _draw_hex(hex):
	var line = Line2D.new()
	line.width = 2.0
	line.default_color = Color(0, 0, 0, 0.03)
	
	for point in grid.polygon_corners(hex):
		line.add_point(point)
		
	line.add_point(line.points[0])  # Close the cell outline
	add_child(line)		


func _add_unit(hex: Hex, units_display: Node = self):
	"""TODO: This will be replaced by a map generator or loader."""
	var unit
	if randi() % 10 > 8:
		unit = Leg.instance()
		unit.position = grid.hex_to_pixel(hex)
		unit.z_index = ZINDEX.UNITS
		units_display.add_child(unit)
	return unit
	

func _get_identifier(x: int, y: int):
	return ("%s%s" % [x, y]).sha256_text()


func hover(pos: Vector2):
	"""Handle map hover logic, displaying the corresponding information."""
	var hex = grid.pixel_to_hex(pos)	
	
	if not grid.hex_valid(hex):
		$SelectionDisplay.reset_highlight()
	else:
		$SelectionDisplay.highlight_cell(hex, grid.polygon_corners(hex))


func _input(event):
	if event is InputEventMouseButton:
		if (event.button_index == BUTTON_LEFT and event.pressed):
			_on_mouse_down(event.position)
		elif(event.button_index == BUTTON_LEFT and not event.pressed):
			_on_mouse_up(event.position)

	elif event is InputEventMouseMotion:
		hover(event.position)


func _on_mouse_down(pos: Vector2):
	var hex = grid.pixel_to_hex(pos)
	
	if not grid.hex_valid(hex):
		selection.cell = null
		return
	
	var state = map[_get_identifier(hex.x, hex.y)]
	
	# If there's an unit on the selected cell we set it as the selection
	# else we return to the initial state.
	if state["unit"]:
		selection.cell = state
		$SelectionDisplay.show_movement_area(grid, grid.neighbors(hex, state["unit"].movement_range))
	else:
		selection.cell = null	


func _on_mouse_up(pos: Vector2):
	var hex = grid.pixel_to_hex(pos)
	
	if not grid.hex_valid(hex):
		selection.cell = null
		return
	
	if not selection.cell:
		return
	
	var state = map[_get_identifier(hex.x, hex.y)]  # The state associated with the current hex
	
	$SelectionDisplay.reset_movement_area()
	
	# If the selected cell is not the same as the previous one
	# we start the movement logic, by checking if the intended
	# movement is possible and if it is we request the unit to move. 
	if not grid.hex_equal(hex, selection.cell["hex"]):
		var target_pos = _target_movement(selection.cell, hex)
		if target_pos:
			selection.cell["unit"].move_to(grid.hex_to_pixel(hex))  # Move unit to hex cell
			state["unit"] = selection.cell["unit"]  # Add unit to new cell status
			selection.cell["unit"] = null  # Remove unit from current cell			
		
	selection.cell = state


func _target_movement(state, target_hex):
	"""Validates if the given unit can move from its position to the 'target_hex'.
	
	If any of the validations are not met then `null` will be returned, else a
	coordinate is returned.
	
	The validations to be performed are:
		* Does the targe exist?
		* Is the distance between cells within the range of the unit?
		* Is the new cell occupied?
	"""
	if not target_hex:
		push_warning("The target cell does not exist.")
		return
	
	var current_hex = state["hex"]
	var unit = state["unit"]
	
	var distance = grid.distance(current_hex, target_hex)
	if distance > unit.movement_range + 1:
		push_warning("The selected unit cannot move %s, only %s." % [distance, unit.movement_range + 1])
		return 
	
	if map[_get_identifier(target_hex.x, target_hex.y)]["unit"]:
		push_warning("The target cell is occupied")
		return
	
	return grid.hex_to_pixel(target_hex)
