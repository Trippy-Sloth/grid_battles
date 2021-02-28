extends Reference

export(Vector2) var hex_scale = Vector2(1, 1)

var cells = []
var layout
var display_type
var size

enum MODES {
	FLAT,
	POINTY
}

enum LAYOUT {
	HEXAGON,
	RECT
}

var NORTH = Hex.new(0, 1, -1)
var NORTH_EAST = Hex.new(1, 0, -1)
var SOUTH_EAST = Hex.new(1, -1, 0)
var SOUTH = Hex.new(0, -1, 1)
var SOUTH_WEST = Hex.new(-1, 0, 1)
var NORTH_WEST = Hex.new(-1, 1, 0)
var DIRECTIONS = [NORTH, NORTH_EAST, SOUTH_EAST, SOUTH, SOUTH_WEST, NORTH_WEST]

var orientation_pointy: Orientation = Orientation.new(sqrt(3.0), sqrt(3.0) / 2.0, 0.0, 3.0 / 2.0, sqrt(3.0) / 3.0, -1.0 / 3.0, 0.0, 2.0 / 3.0, 0.5);
var orientation_flat: Orientation = Orientation.new(3.0 / 2.0, 0.0, sqrt(3.0) / 2.0, sqrt(3.0), 2.0 / 3.0, 0.0, -1.0 / 3.0, sqrt(3.0) / 3.0, 0.0);


func _init(mode: int, cell_size: Vector2, origin: Vector2):
	match mode:
		MODES.FLAT:
			layout = Layout.new(orientation_flat, cell_size, origin)
		MODES.POINTY:
			layout = Layout.new(orientation_pointy, cell_size, origin)
		_:
			push_error("The given mode is not available. Please select either FLAT({}) or POINTY({}).".format(MODES.FLAT, MODES.POINTY))


func generate(_size: int, _display_type: int):
	size = _size
	display_type = _display_type
	match display_type:
		LAYOUT.RECT:
			_rect_layout(size)
		LAYOUT.HEXAGON:
			_hexagon_layout(size)
		_:
			push_error("The given layout was not found. Please provide either HEAXGON({}) or RECT({})".format(LAYOUT.HEXAGON, LAYOUT.RECT))
		

func _rect_layout(_size):
	var q_offset
	for q in range(_size):
		q_offset = floor(q / float(2))
		for r in range(-q_offset, _size - q_offset):
			cells.append(Hex.new(q, r, -q - r))


func _hexagon_layout(_size):
	var radius = _size / 2
	var r1
	var r2
	for x in range(-radius, radius + 1):
		r1 = max(-radius, -x - radius)
		r2 = min(radius, -x + radius)
		for y in range(r1, r2 + 1):
			cells.append(Hex.new(x, y, -x - y))


func hex_equal(a: Hex, b: Hex):
	return a.x == b.x and a.y == b.y and a.z == b.z


func hex_add(a: Hex, b: Hex) -> Hex:
	return Hex.new(a.x + b.x, a.y + b.y, a.z + b.z)


func hex_subtract(a: Hex, b: Hex) -> Hex:
	return Hex.new(a.x - b.x, a.y - b.y, a.z - b.z)


func hex_mult(a: Hex, k: int) -> Hex:
	return Hex.new(a.x * k, a.y * k, a.z * k)
	

func length(hex: Hex):
	return int((abs(hex.x) + abs(hex.y) + abs(hex.z)) / 2)


func distance(a: Hex, b: Hex):
	return length(hex_subtract(a, b))


func direction(dir: int):
	assert(0 <= dir && dir < 6)
	return DIRECTIONS[dir]


func neighbor(hex: Hex, dir: int):
	return hex_add(hex, direction(dir))

func neighbors(hex: Hex, distance: int = 1):
	var neighbors_list = []
	var nei
	
	for x in range(-distance, distance + 1):
		for y in range(max(-distance, -x-distance), min(-x+distance, distance) + 1):
			nei = hex_add(hex, Hex.new(x, y, -x - y))
			if hex_valid(nei):
				neighbors_list.append(nei)
	return neighbors_list


func hex_valid(hex: Hex):
	"""This function validates if the given Hex has coordinates inside the current layout"""
	match display_type:
		LAYOUT.RECT:
			return (
				hex.x >= 0 and hex.x <= size 
				and hex.y >= 0 and hex.y <= size 
				and hex.z >= 0 and hex.z <= size
			)
		LAYOUT.HEXAGON:
			var radius = size / 2
			return (
				hex.x >= -radius and hex.x <= radius 
				and hex.y >= -radius and hex.y <= radius 
				and hex.z >= -radius and hex.z <= radius
			)

func hex_to_pixel(hex: Hex):
	var orient: Orientation = layout.orientation
	var x = (orient.f0 * hex.x + orient.f1 * hex.y) * layout.size.x
	var y = (orient.f2 * hex.x + orient.f3 * hex.y) * layout.size.y
	return Vector2(x + layout.origin.x, y + layout.origin.y)


func pixel_to_hex(p: Vector2):
	var orient: Orientation = layout.orientation
	var point = Vector2((p.x - layout.origin.x) / layout.size.x, (p.y - layout.origin.y) / layout.size.y)
	var x: float = orient.b0 * point.x + orient.b1 * point.y
	var y: float = orient.b2 * point.x + orient.b3 * point.y
	return get_rounded_hex(x, y, -x - y)


func hex_corner_offset(corner: int):
	var _size: Vector2 = layout.size
	var angle: float = 2.0 * PI * (layout.orientation.start_angle + corner) / 6
	return Vector2(_size.x * cos(angle), _size.y * sin(angle))


func polygon_corners(hex: Hex):
	var corners = []
	var offset: Vector2
	var center: Vector2 = hex_to_pixel(hex)
	for i in range(6):
		offset = hex_corner_offset(i)
		corners.insert(0, Vector2(center.x + offset.x, center.y + offset.y))
	return corners


func get_rounded_hex(x: float, y: float, z: float):
	"""Return a Hex by rounding the given coordinates."""
	var rx = round(x)
	var ry = round(y)
	var rz = round(z)

	var x_diff = abs(rx - x)
	var y_diff = abs(ry - y)
	var z_diff = abs(rz - z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Hex.new(rx, ry, rz)
	

class Orientation:
	var f0: float
	var f1: float
	var f2: float
	var f3: float 
	var b0: float
	var b1: float
	var b2: float
	var b3: float
	var start_angle # Multiples of 60º
	
	func _init(_f0, _f1, _f2, _f3, _b0, _b1, _b2, _b3, _start_angle):
		self.f0 = _f0
		self.f1 = _f1
		self.f2 = _f2
		self.f3 = _f3
		self.b0 = _b0
		self.b1 = _b1
		self.b2 = _b2
		self.b3 = _b3
		self.start_angle = _start_angle

class Layout:
	var orientation: Orientation
	var size: Vector2
	var origin: Vector2
	
	func _init(_orientation: Orientation, _size: Vector2, _origin: Vector2):
		self.orientation = _orientation
		self.size = _size
		self.origin = _origin
