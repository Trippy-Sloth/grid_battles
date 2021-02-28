"""
This object is responsible for everything regarding the map, including drawing the Grid
storing the object's positions on cells and checks like the ability to move or returning the 
object stored at a certain cell.
"""
extends Node2D

# Scenes and scripts imports
var Grid = load("res://scripts/Grid.gd")

export(Vector2) var cell_size = Vector2(35, 45)

# The number of cells for each grid axis, x and y. 
# Grid total size is (grid_cell_number + 1)^2 - grid_cell_number * 2
export(int) var grid_cell_number = 8

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

# Unit types are preload for instancing
var Map = load("res://scripts/Map.gd")

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


func initialize():	
	randomize()
	origin = get_viewport_rect().size / 2 if not origin else origin
	grid = Grid.new(mode, cell_size, origin)
	grid.generate(grid_cell_number, layout)
	
	# Draw cells and populate map
	for hex in grid.cells:
		_draw_hex(hex)
	
	return grid.cells


func _draw_hex(hex):
	var line = Line2D.new()
	line.width = 2.0
	line.default_color = Color(0, 0, 0, 0.03)
	
	for point in grid.polygon_corners(hex):
		line.add_point(point)
		
	line.add_point(line.points[0])  # Close the cell outline
	$Grid.add_child(line)		


func toggle_grid(toggle: bool):
	$Grid.visible = toggle


func hover(pos: Vector2):
	"""Handle map hover logic, displaying the corresponding information."""
	var hex = grid.pixel_to_hex(pos)	
	
	if not grid.hex_valid(hex):
		$SelectionDisplay.reset_highlight()
	else:
		$SelectionDisplay.highlight_cell(grid.polygon_corners(hex))



func get_hex(pos: Vector2):
	var hex = grid.pixel_to_hex(pos)
	if not grid.hex_valid(hex):
		return
	return hex


func get_coordinates(hex: Hex):
	return grid.hex_to_pixel(hex)


func show_movement_area(hex: Hex, movement_range: int):
	$SelectionDisplay.show_movement_area(grid, grid.neighbors(hex, movement_range))


func reset_movement_area():
	$SelectionDisplay.reset_movement_area()


func distance(from: Hex, target: Hex):
	return grid.distance(from, target) 


func get_target(from: Hex, target: Hex, movement_range: int):
	# If the selected cell is not the same as the previous one
	# we start the movement logic, by checking if the intended
	# movement is possible and if it is we request the unit to move. 
	if grid.hex_equal(from, target):
		return 
	return _target_movement(from, target, movement_range)
	

func _target_movement(current_hex, target_hex, movement_range):
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
	
	var distance = grid.distance(current_hex, target_hex)
	if distance > movement_range:
		push_warning("The selected unit cannot move %s, only %s." % [distance, movement_range])
		return 
	
	return grid.hex_to_pixel(target_hex)
