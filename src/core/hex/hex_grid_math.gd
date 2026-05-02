extends RefCounted
class_name HexGridMath

const SQRT_3 := 1.7320508075688772

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
]


static func normalize_direction_index(index: int) -> int:
	return ((index % 6) + 6) % 6


static func direction(index: int) -> Vector2i:
	return DIRECTIONS[normalize_direction_index(index)]


static func neighbor(coord: Vector2i, direction_index: int) -> Vector2i:
	return coord + direction(direction_index)


static func neighbors(coord: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dir in DIRECTIONS:
		result.append(coord + dir)
	return result


static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return int((abs(dq) + abs(dr) + abs(dq + dr)) / 2)


static func radius_count(radius: int) -> int:
	if radius < 0:
		return 0
	return 1 + 3 * radius * (radius + 1)


static func coords_in_radius(radius: int, center := Vector2i.ZERO) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	if radius < 0:
		return coords

	for q in range(-radius, radius + 1):
		var r_min: int = max(-radius, -q - radius)
		var r_max: int = min(radius, -q + radius)
		for r in range(r_min, r_max + 1):
			coords.append(center + Vector2i(q, r))

	return coords


static func ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	if radius < 0:
		return coords
	if radius == 0:
		coords.append(center)
		return coords

	var current := center + direction(4) * radius
	for side in range(6):
		for _step in range(radius):
			coords.append(current)
			current += direction(side)

	return coords


static func axial_to_world(coord: Vector2i, hex_radius: float) -> Vector2:
	return Vector2(
		hex_radius * SQRT_3 * (float(coord.x) + float(coord.y) * 0.5),
		hex_radius * 1.5 * float(coord.y)
	)


static func world_to_axial(world: Vector2, hex_radius: float) -> Vector2i:
	var q := (SQRT_3 / 3.0 * world.x - 1.0 / 3.0 * world.y) / hex_radius
	var r := (2.0 / 3.0 * world.y) / hex_radius
	return _cube_round(q, -q - r, r)


static func _cube_round(x: float, y: float, z: float) -> Vector2i:
	var rx := roundi(x)
	var ry := roundi(y)
	var rz := roundi(z)

	var x_diff: float = absf(float(rx) - x)
	var y_diff: float = absf(float(ry) - y)
	var z_diff: float = absf(float(rz) - z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(rx, rz)
