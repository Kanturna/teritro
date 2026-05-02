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
@export var simple_lod_zoom := 0.55
@export var overview_lod_zoom := 0.35
@export var grid_visible := true:
	set(value):
		grid_visible = value
		if is_inside_tree():
			queue_redraw()

var _base_polygon := PackedVector2Array()
var _map_outline_polygon := PackedVector2Array()
var _scratch_polygon := PackedVector2Array()
var _grid_line_points := PackedVector2Array()
var _visible_corners: Array[Vector2] = []
var _hexes: Array[Vector2i] = []
var _visible_hex_count := 0
var _drawn_hex_count := 0
var _candidate_hex_count := 0
var _culled_by_map_count := 0
var _culled_by_view_count := 0
var _draw_call_estimate := 0
var _draw_ms := 0.0
var _lod_mode := "full"


func _ready() -> void:
	_visible_corners.resize(4)
	_rebuild_polygon()
	_rebuild_map()


func get_total_hex_count() -> int:
	return _hexes.size()


func get_visible_hex_count() -> int:
	return _visible_hex_count


func get_debug_metrics() -> Dictionary:
	return {
		"lod": _lod_mode,
		"visible": _visible_hex_count,
		"drawn": _drawn_hex_count,
		"candidates": _candidate_hex_count,
		"culled_map": _culled_by_map_count,
		"culled_view": _culled_by_view_count,
		"draw_calls": _draw_call_estimate,
		"draw_ms": _draw_ms,
		"grid_visible": grid_visible,
	}


func get_current_lod_mode() -> String:
	return _get_lod_for_zoom(_get_camera_zoom())


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
	var start_usec := Time.get_ticks_usec()
	_visible_hex_count = 0
	_drawn_hex_count = 0
	_candidate_hex_count = 0
	_culled_by_map_count = 0
	_culled_by_view_count = 0
	_draw_call_estimate = 0
	_lod_mode = _get_lod_for_zoom(_get_camera_zoom())

	if _lod_mode == "overview":
		_draw_overview_map()
		_draw_ms = float(Time.get_ticks_usec() - start_usec) / 1000.0
		return

	_draw_overview_fill()
	if not grid_visible:
		_draw_ms = float(Time.get_ticks_usec() - start_usec) / 1000.0
		return

	_draw_axis_lines()
	_grid_line_points.clear()

	var bounds := _get_visible_axial_bounds()
	var visible_rect := _get_visible_world_rect()

	for q in range(bounds.position.x, bounds.end.x + 1):
		for r in range(bounds.position.y, bounds.end.y + 1):
			_candidate_hex_count += 1
			var coord := Vector2i(q, r)
			var center: Vector2 = HexGridMath.axial_to_world(coord, hex_radius)
			if not _is_inside_map(coord):
				_culled_by_map_count += 1
				continue
			if not visible_rect.has_point(to_global(center)):
				_culled_by_view_count += 1
				continue
			_append_hex_lines(center)
			_visible_hex_count += 1
			_drawn_hex_count += 1

	if _grid_line_points.size() > 0:
		draw_multiline(_grid_line_points, outline_color, 1.0, true)
		_draw_call_estimate += 1

	_draw_ms = float(Time.get_ticks_usec() - start_usec) / 1000.0


func _rebuild_map() -> void:
	_hexes = HexGridMath.coords_in_radius(map_radius)
	_map_outline_polygon = _build_map_outline_polygon()
	if is_inside_tree():
		queue_redraw()


func _rebuild_polygon() -> void:
	_base_polygon = _build_hex_polygon_points()
	_map_outline_polygon = _build_map_outline_polygon()
	_scratch_polygon.resize(6)
	if is_inside_tree():
		queue_redraw()


func _append_hex_lines(center: Vector2) -> void:
	var start_index := _grid_line_points.size()
	_grid_line_points.resize(start_index + 12)

	for i in range(6):
		var point_a := center + _base_polygon[i]
		var point_b := center + _base_polygon[(i + 1) % 6]
		var point_index := start_index + i * 2
		_grid_line_points[point_index] = point_a
		_grid_line_points[point_index + 1] = point_b


func _draw_overview_map() -> void:
	_draw_overview_fill()
	if grid_visible:
		_draw_axis_lines()


func _draw_overview_fill() -> void:
	draw_colored_polygon(_map_outline_polygon, fill_color)
	_draw_call_estimate += 1


func _draw_axis_lines() -> void:
	for direction_index in [0, 1, 2]:
		var start: Vector2 = HexGridMath.axial_to_world(
			HexGridMath.direction(direction_index + 3) * map_radius,
			hex_radius
		)
		var end: Vector2 = HexGridMath.axial_to_world(
			HexGridMath.direction(direction_index) * map_radius,
			hex_radius
		)
		draw_line(start, end, axis_color, 2.0, true)
		_draw_call_estimate += 1


func _is_inside_map(coord: Vector2i) -> bool:
	return HexGridMath.distance(coord, Vector2i.ZERO) <= map_radius


func _build_hex_polygon_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(6)
	for i in range(6):
		var angle := deg_to_rad(30.0 + 60.0 * float(i))
		points[i] = Vector2(cos(angle), sin(angle)) * hex_radius
	return points


func _build_map_outline_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(6)
	var outline_radius := hex_radius * (float(map_radius) + 0.75)
	for i in range(6):
		var angle := deg_to_rad(30.0 + 60.0 * float(i))
		points[i] = Vector2(cos(angle), sin(angle)) * outline_radius
	return points


func _get_camera_zoom() -> float:
	var viewport := get_viewport()
	if viewport == null:
		return 1.0
	var camera := viewport.get_camera_2d()
	if camera == null:
		return 1.0
	return camera.zoom.x


func _get_lod_for_zoom(zoom: float) -> String:
	if zoom <= overview_lod_zoom:
		return "overview"
	if zoom <= simple_lod_zoom:
		return "simple"
	return "full"


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
