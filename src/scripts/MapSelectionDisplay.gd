extends Node

export(Color) var highlight_color = Color(1, 1, 1, 0.1)
export(Color) var movement_color = Color(1, 1, 1, 0.1)

var highlight: Polygon2D
var movement_highlights = {}


func show_movement_area(grid, hexes):
	var selector
	for hex in hexes:
		selector = Polygon2D.new()
		selector.color = movement_color
		selector.polygon = grid.polygon_corners(hex)
		movement_highlights[_get_identifier(hex.x, hex.y)] = selector
		add_child(selector)


func reset_movement_area():
	var selector
	for key in movement_highlights:
		selector = movement_highlights[key]
		remove_child(selector)		
	movement_highlights.clear()
		

func highlight_cell(hex, points):
	if not highlight:
		highlight = Polygon2D.new()
		add_child(highlight)
		
	highlight.color = highlight_color
	highlight.polygon = points


func reset_highlight():
	remove_child(highlight)
	highlight = null
	

func _get_identifier(x: int, y: int):
	return ("%s%s" % [x, y]).sha256_text()
