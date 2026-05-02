extends SceneTree

const HexGridMath = preload("res://src/core/hex/hex_grid_math.gd")

var _failures: Array[String] = []


func _init() -> void:
	_test_neighbors()
	_test_distance_symmetry()
	_test_radius_counts()
	_test_world_roundtrip()
	_test_ring()

	if _failures.is_empty():
		print("HexGridMath tests passed.")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)


func _test_neighbors() -> void:
	var center := Vector2i.ZERO
	var neighbors := HexGridMath.neighbors(center)
	_assert_eq(neighbors.size(), 6, "center has 6 neighbors")

	var seen := {}
	for coord in neighbors:
		seen[coord] = true
		_assert_eq(HexGridMath.distance(center, coord), 1, "neighbor distance is 1")
	_assert_eq(seen.size(), 6, "neighbors are unique")


func _test_distance_symmetry() -> void:
	var samples := [
		Vector2i.ZERO,
		Vector2i(3, -2),
		Vector2i(-4, 1),
		Vector2i(7, -5),
	]

	for a in samples:
		for b in samples:
			_assert_eq(
				HexGridMath.distance(a, b),
				HexGridMath.distance(b, a),
				"distance symmetry %s %s" % [a, b]
			)


func _test_radius_counts() -> void:
	for radius in [0, 1, 2, 30, 80]:
		_assert_eq(
			HexGridMath.coords_in_radius(radius).size(),
			HexGridMath.radius_count(radius),
			"radius count %d" % radius
		)


func _test_world_roundtrip() -> void:
	for coord in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-3, 2), Vector2i(10, -5)]:
		var world: Vector2 = HexGridMath.axial_to_world(coord, 18.0)
		var rounded: Vector2i = HexGridMath.world_to_axial(world, 18.0)
		_assert_eq(rounded, coord, "world roundtrip %s" % coord)


func _test_ring() -> void:
	_assert_eq(HexGridMath.ring(Vector2i.ZERO, 0).size(), 1, "ring 0 size")
	_assert_eq(HexGridMath.ring(Vector2i.ZERO, 1).size(), 6, "ring 1 size")
	_assert_eq(HexGridMath.ring(Vector2i.ZERO, 3).size(), 18, "ring 3 size")


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s, got %s" % [label, expected, actual])
