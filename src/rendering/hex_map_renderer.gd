extends Node2D
class_name HexMapRenderer

const HexGridMath = preload("res://src/core/hex/hex_grid_math.gd")

@export_range(1, 250, 1) var map_radius := 80:
	set(value):
		map_radius = value
		_rebuild_map()
@export var hex_radius := 18.0:
	set(value):
		hex_radius = max(value, 1.0)
		_rebuild_polygon()
@export var cull_padding_hexes := 3
@export var fill_color := Color(0.055, 0.075, 0.085, 1.0)
@export var outline_color := Color(0.23, 0.38, 0.42, 0.7)
@export var axis_color := Color(0.45, 0.78, 0.82, 0.95)

var _base_polygon := PackedVector2Array()
var _scratch_polygon := PackedVector2Array()
var _visible_corners: Array[Vector2] = []
var _hexes: Array[Vector2i] = []
var _visible_hex_count := 0


func _ready() -> void:
	_visible_corners.resize(4)
	_rebuild_polygon()
	_rebuild_map()


func get_total_hex_count() -> int:
	return _hexes.size()


func get_visible_hex_count() -> int:
	return _visible_hex_count


func estimate_visible_hex_count() -> int:
	var count := 0
	var bounds := _get_visible_axial_bounds()
	var visible_rect := _get_visible_world_rect()
	for q in range(bounds.position.x, bounds.end.x + 1):
		for r in range(bounds.position.y, bounds.end.y + 1):
			var coord := Vector2i(q, r)
			var center: Vector2 = HexGridMath.axial_to_world(coord, hex_radius)
			if _is_inside_map(coord) and visible_rect.has_point(to_global(center)):
				count += 1
	return count


func _draw() -> void:
	_visible_hex_count = 0
	var bounds := _get_visible_axial_bounds()
	var visible_rect := _get_visible_world_rect()

	for q in range(bounds.position.x, bounds.end.x + 1):
		for r in range(bounds.position.y, bounds.end.y + 1):
			var coord := Vector2i(q, r)
			var center: Vector2 = HexGridMath.axial_to_world(coord, hex_radius)
			if not _is_inside_map(coord):
				continue
			if not visible_rect.has_point(to_global(center)):
				continue
			_draw_hex(coord, center)
			_visible_hex_count += 1


func _rebuild_map() -> void:
	_hexes = HexGridMath.coords_in_radius(map_radius)
	if is_inside_tree():
		queue_redraw()


func _rebuild_polygon() -> void:
	_base_polygon = _build_hex_polygon_points()
	_scratch_polygon.resize(6)
	if is_inside_tree():
		queue_redraw()


func _draw_hex(coord: Vector2i, center: Vector2) -> void:
	for i in range(6):
		_scratch_polygon[i] = center + _base_polygon[i]

	var color := fill_color
	if coord.x == 0 or coord.y == 0 or coord.x + coord.y == 0:
		color = fill_color.lerp(axis_color, 0.18)

	draw_colored_polygon(_scratch_polygon, color)
	for i in range(6):
		draw_line(
			_scratch_polygon[i],
			_scratch_polygon[(i + 1) % 6],
			outline_color,
			1.0,
			true
		)


func _is_inside_map(coord: Vector2i) -> bool:
	return HexGridMath.distance(coord, Vector2i.ZERO) <= map_radius


func _build_hex_polygon_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(6)
	for i in range(6):
		var angle := deg_to_rad(30.0 + 60.0 * float(i))
		points[i] = Vector2(cos(angle), sin(angle)) * hex_radius
	return points


func _get_visible_world_rect() -> Rect2:
	var viewport := get_viewport()
	if viewport == null:
		var full_size := Vector2.ONE * hex_radius * float(map_radius * 4)
		return Rect2(-full_size * 0.5, full_size)

	var camera := viewport.get_camera_2d()
	if camera == null:
		var full_size := Vector2.ONE * hex_radius * float(map_radius * 4)
		return Rect2(-full_size * 0.5, full_size)

	var viewport_size := get_viewport_rect().size
	var zoom := Vector2(max(camera.zoom.x, 0.001), max(camera.zoom.y, 0.001))
	var world_size := Vector2(viewport_size.x / zoom.x, viewport_size.y / zoom.y)
	var center := camera.get_screen_center_position()
	return Rect2(center - world_size * 0.5, world_size)


func _get_visible_axial_bounds() -> Rect2i:
	var rect := _get_visible_world_rect()

	_visible_corners[0] = rect.position
	_visible_corners[1] = rect.position + Vector2(rect.size.x, 0.0)
	_visible_corners[2] = rect.position + rect.size
	_visible_corners[3] = rect.position + Vector2(0.0, rect.size.y)

	var min_q := map_radius
	var max_q := -map_radius
	var min_r := map_radius
	var max_r := -map_radius

	for corner in _visible_corners:
		var axial: Vector2i = HexGridMath.world_to_axial(to_local(corner), hex_radius)
		min_q = min(min_q, axial.x)
		max_q = max(max_q, axial.x)
		min_r = min(min_r, axial.y)
		max_r = max(max_r, axial.y)

	min_q = clampi(min_q - cull_padding_hexes, -map_radius, map_radius)
	max_q = clampi(max_q + cull_padding_hexes, -map_radius, map_radius)
	min_r = clampi(min_r - cull_padding_hexes, -map_radius, map_radius)
	max_r = clampi(max_r + cull_padding_hexes, -map_radius, map_radius)

	return Rect2i(
		Vector2i(min_q, min_r),
		Vector2i(max_q - min_q, max_r - min_r)
	)
