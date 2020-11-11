extends Reference

export(Vector2) var hex_scale = Vector2(1, 1)

var cells = []
var layout

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
	if (mode == MODES.FLAT):
		layout = Layout.new(orientation_flat, cell_size, origin)
	elif (mode == MODES.POINTY):
		layout = Layout.new(orientation_pointy, cell_size, origin)
	else:
		push_error("The given mode is not available. Please select either FLAT({}) or POINTY({}).".format(MODES.FLAT, MODES.POINTY))


func generate(size: int, _layout: int):
	if _layout == LAYOUT.RECT:
		_rect_layout(size)
	elif _layout == LAYOUT.HEXAGON:
		_hexagon_layout(size)
	else:
		push_error("The given layout was not found. Please provide either HEAXGON({}) or RECT({})".format(LAYOUT.HEXAGON, LAYOUT.RECT))
		

func _rect_layout(size):
	var q_offset
	for q in range(size):
		q_offset = floor(q / 2)
		for r in range(-q_offset, size - q_offset):
			cells.append(Hex.new(q, r, -q - r))


func _hexagon_layout(size):
	var radius = size / 2
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
	return int((abs(hex.x) + abs(hex.x) + abs(hex.x)) / 2)


func distance(a: Hex, b: Hex):
	return length(hex_subtract(a, b))


func direction(dir: int):
	assert(0 <= dir && dir < 6)
	return DIRECTIONS[dir]


func neighbor(hex: Hex, dir: int):
	return hex_add(hex, direction(dir))


func hex_to_pixel(_layout: Layout, hex: Hex):
	var orient: Orientation = _layout.orientation
	var x = (orient.f0 * hex.x + orient.f1 * hex.y) * _layout.size.x
	var y = (orient.f2 * hex.x + orient.f3 * hex.y) * _layout.size.y
	return Vector2(x + _layout.origin.x, y + _layout.origin.y)


func pixel_to_hex(_layout: Layout, p: Vector2):
	var orient: Orientation = _layout.orientation
	var point = Vector2((p.x - _layout.origin.x) / _layout.size.x, (p.y - _layout.origin.y) / _layout.size.y)
	var x: float = orient.b0 * point.x + orient.b1 * point.y
	var y: float = orient.b2 * point.x + orient.b3 * point.y
	return get_rounded_hex(x, y, -x - y)


func hex_corner_offset(_layout: Layout, corner: int):
	var size: Vector2 = _layout.size
	var angle: float = 2.0 * PI * (_layout.orientation.start_angle + corner) / 6
	return Vector2(size.x * cos(angle), size.y * sin(angle))


func polygon_corners(_layout: Layout, hex: Hex):
	var corners = []
	var offset: Vector2
	var center: Vector2 = hex_to_pixel(_layout, hex)
	for i in range(6):
		offset = hex_corner_offset(_layout, i)
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
