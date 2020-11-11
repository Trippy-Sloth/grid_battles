extends Reference
class_name Hex

var x = 0 setget ,get_x
var y = 0 setget ,get_y
var z = 0 setget ,get_z
var cube_coords = Vector3(x, y, z) setget set_cube_coords, get_cube_coords


func get_x():
	return cube_coords.x


func get_y():
	return cube_coords.y

	
func get_z():
	return cube_coords.z


func _init(_x: int, _y: int, _z: int):
	assert(_x + _y + _z == 0)
	cube_coords = Vector3(_x, _y, _z)


func axial_to_cube_coords(val):
	var _x = val.x
	var _y = val.y
	return Vector3(_x, _y, -_x - _y)


func round_coords(val):
	# Rounds floaty coordinate to the nearest whole number cube coords
	if typeof(val) == TYPE_VECTOR2:
		val = axial_to_cube_coords(val)
	
	# Straight round them
	var rounded = Vector3(round(val.x), round(val.y), round(val.z))
	
	# But recalculate the one with the largest diff so that x+y+z=0
	var diffs = (rounded - val).abs()
	if diffs.x > diffs.y and diffs.x > diffs.z:
		rounded.x = -rounded.y - rounded.z
	elif diffs.y > diffs.z:
		rounded.y = -rounded.x - rounded.z
	else:
		rounded.z = -rounded.x - rounded.y
	
	return rounded


func get_cube_coords():
	# Returns a Vector3 of the cube coordinates
	return cube_coords
	
	
func set_cube_coords(val):
	# Sets the position from a Vector3 of cube coordinates
	if abs(val.x + val.y + val.z) > 0.0001:
		print("WARNING: Invalid cube coordinates for hex (x+y+z!=0): ", val)
		return
	cube_coords = round_coords(val)


func _to_string():
	return "X:%s,Y:%s,Z:%s)" % [cube_coords.x, cube_coords.y, cube_coords.z]


