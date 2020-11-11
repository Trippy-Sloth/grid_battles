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
	SELECTED,
	MOVING,
	ATTACKING,
	RESETTING
}


# Create a class to define a schema for selection data storage.
# Y U CREATE CLASES?!?
class Selection:
	var state = STATES.INITIAL
	var cell = null
	
var selection = Selection.new()


# The origin point of the grid. Dependending on the type of grid the origin will 
# define from where it expands. Remember that HEXAGON grids exapand in circles
# outwards, while RECT grids expand to the right and down.
# The default value will be the center of the viewport.
export(Vector2) var origin

# Reference to the Grid class
var grid

# This object will be used to display the selected cell on the map.
var selector: Polygon2D

# The state of the world.
# TODO: This state can be loaded from file or another persistent resource type.
var map = {}


func _ready():	
	randomize()
	origin = get_viewport_rect().size / 2 if not origin else origin
	grid = Grid.new(mode, cell_size, origin)
	grid.generate(grid_cell_number, layout)
	
	# Create Node that will group all units
	var units_display = Node.new()
	
	# Draw cells and populate state
	for hex in grid.cells:		
		map[_get_identifier(hex.x, hex.y)] = {
			"hex": hex,
			"unit": _add_unit(hex, units_display)
		}
			
		var line = Line2D.new()
		line.width = 2.0
		line.default_color = Color(0, 0, 0, 0.03)
		
		for point in grid.polygon_corners(grid.layout, hex):
			line.add_point(point)
			
		line.add_point(line.points[0])  # Close the cell outline
		add_child(line)		
	add_child(units_display)


func _add_unit(hex: Hex, units_display: Node):
	var unit
	if randi() % 10 > 8:
		unit = Leg.instance()
		unit.position = grid.hex_to_pixel(grid.layout, hex)
		unit.z_index = ZINDEX.UNITS
		units_display.add_child(unit)
	return unit
	

func _get_identifier(x: int, y: int):
	return ("%s%s" % [x, y]).sha256_text()


func hover(pos: Vector2):
	var hex = grid.pixel_to_hex(grid.layout, pos)	
	
	# Check if selected hex coordinates are valid for current configurations.
	if not hex_valid(hex.x, hex.y):
		if selector:
			remove_child(selector)
			selector = null
		return	
	
	if selector == null:
		selector = Polygon2D.new()
		selector.color = Color(1, 1, 1, 0.1)
		add_child(selector)
		
	selector.polygon = grid.polygon_corners(grid.layout, hex)


func handle_action(pos: Vector2):
	var hex = grid.pixel_to_hex(grid.layout, pos)
	var state_data = map[_get_identifier(hex.x, hex.y)]
	
	match selection.state:
		STATES.INITIAL:
			if hex and state_data["unit"]:
				selection.state = STATES.SELECTED
				selection.cell = state_data
		STATES.SELECTED:
			
			# If the current selected cell is empty we can move the selected 
			# unit to that cell. We must instruct the unit to move, by calling
			# the `move_to` method on the Unit and by updating the map status,
			# to reflect the change.
			if not state_data["unit"]:
				selection.cell["unit"].move_to(grid.hex_to_pixel(grid.layout, hex))
				map[_get_identifier(hex.x, hex.y)]["unit"] = selection.cell["unit"]
				selection.cell["unit"] = null
				selection.cell = null
				
			selection.state = STATES.INITIAL


func hex_valid(x: int, y: int):
	var radius = grid_cell_number / 2
	var z = -x - y
	return (x >= -radius and x <= radius 
			and y >= -radius and y <= radius
			and z >=-radius and z <= radius)


func get_cell_for_position(pos: Vector2):
	var hex = grid.pixel_to_hex(grid.layout, pos)
	return map[_get_identifier(hex.x, hex.y)] if hex_valid(hex.x, hex.y) else null


func get_cell(x: int, y: int):
	return map[_get_identifier(x, y)] if hex_valid(x, y) else null
	

func get_coord_position(x: int, y: int):
	return grid.hex_to_pixel(grid.layout, map[_get_identifier(x, y)]["hex"]) if hex_valid(x, y) else null
	
