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
@export var fill_color := Color.WHITE
@export var outline_color := Color(0.0, 0.0, 0.0, 0.95)
@export var axis_color := Color(0.0, 0.0, 0.0, 0.35)
@export var simple_lod_zoom := 0.75
@export var overview_lod_zoom := 0.5
@export var grid_line_screen_width := 1.0
@export var overview_line_screen_width := 1.5
@export var map_outline_screen_width := 2.0
@export var default_colony_color := Color(0.1, 0.36, 1.0, 0.45)
@export var grid_line_antialiased := false
@export var grid_line_auto_antialias := true
@export var grid_antialias_line_point_limit := 40000
@export var debug_axis_visible := false:
	set(value):
		debug_axis_visible = value
		if is_inside_tree():
			queue_redraw()
@export var grid_visible := true:
	set(value):
		grid_visible = value
		if is_inside_tree():
			queue_redraw()

var _base_polygon := PackedVector2Array()
var _map_outline_segments := PackedVector2Array()
var _scratch_polygon := PackedVector2Array()
var _grid_line_points := PackedVector2Array()
var _owned_cells: Dictionary = {}
var _colony_colors: Dictionary = {}
var _visible_centers := PackedVector2Array()
var _visible_coords: Array[Vector2i] = []
var _visible_corners: Array[Vector2] = []
var _visible_coord_lookup := {}
var _hexes: Array[Vector2i] = []
var _visible_hex_count := 0
var _drawn_hex_count := 0
var _candidate_hex_count := 0
var _culled_by_map_count := 0
var _culled_by_view_count := 0
var _draw_call_estimate := 0
var _draw_ms := 0.0
var _bounds_ms := 0.0
var _candidate_ms := 0.0
var _line_build_ms := 0.0
var _submit_ms := 0.0
var _line_point_count := 0
var _lod_mode := "full"
var _cell_grid_drawn := false
var _grid_line_effective_antialiased := false
var _owned_cells_drawn := 0


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
		"bounds_ms": _bounds_ms,
		"candidate_ms": _candidate_ms,
		"line_build_ms": _line_build_ms,
		"submit_ms": _submit_ms,
		"line_points": _line_point_count,
		"grid_visible": grid_visible,
		"cell_grid_drawn": _cell_grid_drawn,
		"debug_axis_visible": debug_axis_visible,
		"grid_line_screen_width": grid_line_screen_width,
		"map_outline_screen_width": map_outline_screen_width,
		"map_outline_segments": int(_map_outline_segments.size() / 2),
		"grid_line_antialiased": grid_line_antialiased,
		"grid_line_auto_antialias": grid_line_auto_antialias,
		"grid_line_effective_antialiased": _grid_line_effective_antialiased,
		"grid_antialias_line_point_limit": grid_antialias_line_point_limit,
		"owned_cells_total": _owned_cells.size(),
		"owned_cells_drawn": _owned_cells_drawn,
	}


func set_territory_snapshot(snapshot: Dictionary, colony_colors: Dictionary) -> void:
	_owned_cells = snapshot.get("cell_owners", {}).duplicate()
	_colony_colors = colony_colors.duplicate()
	if is_inside_tree():
		queue_redraw()


func get_current_lod_mode() -> String:
	return _get_lod_for_zoom(_get_camera_zoom())


func will_draw_cell_grid() -> bool:
	return grid_visible and get_current_lod_mode() == "full"


func needs_camera_redraw() -> bool:
	return will_draw_cell_grid()


func estimate_visible_hex_count() -> int:
	var count := 0
	var bounds := _get_visible_axial_bounds()
	var visible_rect := _get_visible_local_rect()
	for q in range(bounds.position.x, bounds.end.x + 1):
		for r in range(bounds.position.y, bounds.end.y + 1):
			var coord := Vector2i(q, r)
			var center: Vector2 = HexGridMath.axial_to_world(coord, hex_radius)
			if _is_inside_map(coord) and _hex_rect_intersects_view(center, visible_rect):
				count += 1
	return count


func _draw() -> void:
	var start_usec := Time.get_ticks_usec()
	_reset_draw_metrics()
	_lod_mode = _get_lod_for_zoom(_get_camera_zoom())

	if _lod_mode == "overview":
		var overview_submit_start := Time.get_ticks_usec()
		_draw_owned_cells(_get_visible_local_rect())
		_draw_overview_map()
		_submit_ms = _elapsed_ms(overview_submit_start)
		_draw_ms = _elapsed_ms(start_usec)
		return

	if _lod_mode == "simple":
		var simple_submit_start := Time.get_ticks_usec()
		_draw_owned_cells(_get_visible_local_rect())
		_draw_simple_map()
		_submit_ms = _elapsed_ms(simple_submit_start)
		_draw_ms = _elapsed_ms(start_usec)
		return

	if not grid_visible:
		var hidden_submit_start := Time.get_ticks_usec()
		_draw_owned_cells(_get_visible_local_rect())
		_draw_map_outline()
		_draw_debug_axis_lines()
		_submit_ms = _elapsed_ms(hidden_submit_start)
		_draw_ms = _elapsed_ms(start_usec)
		return

	var bounds_start := Time.get_ticks_usec()
	var bounds := _get_visible_axial_bounds()
	var visible_rect := _get_visible_local_rect()
	_bounds_ms = _elapsed_ms(bounds_start)

	var candidate_start := Time.get_ticks_usec()
	_collect_visible_centers(bounds, visible_rect)
	_candidate_ms = _elapsed_ms(candidate_start)

	var line_build_start := Time.get_ticks_usec()
	_build_grid_lines_from_visible_cells()
	_line_build_ms = _elapsed_ms(line_build_start)

	var submit_start := Time.get_ticks_usec()
	_draw_owned_cells(visible_rect)
	_draw_map_outline()
	_draw_debug_axis_lines()
	if _line_point_count > 0:
		_grid_line_effective_antialiased = _should_antialias_grid_lines()
		draw_multiline(
			_grid_line_points,
			outline_color,
			_get_screen_stable_line_width(grid_line_screen_width),
			_grid_line_effective_antialiased
		)
		_draw_call_estimate += 1
		_cell_grid_drawn = true
	_submit_ms = _elapsed_ms(submit_start)

	_draw_ms = _elapsed_ms(start_usec)


func _reset_draw_metrics() -> void:
	_visible_hex_count = 0
	_drawn_hex_count = 0
	_candidate_hex_count = 0
	_culled_by_map_count = 0
	_culled_by_view_count = 0
	_draw_call_estimate = 0
	_draw_ms = 0.0
	_bounds_ms = 0.0
	_candidate_ms = 0.0
	_line_build_ms = 0.0
	_submit_ms = 0.0
	_line_point_count = 0
	_cell_grid_drawn = false
	_grid_line_effective_antialiased = false
	_owned_cells_drawn = 0


func _rebuild_map() -> void:
	_hexes = HexGridMath.coords_in_radius(map_radius)
	_map_outline_segments = _build_map_outline_segments()
	if is_inside_tree():
		queue_redraw()


func _rebuild_polygon() -> void:
	_base_polygon = _build_hex_polygon_points()
	_map_outline_segments = _build_map_outline_segments()
	_scratch_polygon.resize(6)
	if is_inside_tree():
		queue_redraw()


func _collect_visible_centers(bounds: Rect2i, visible_rect: Rect2) -> void:
	var q_count := bounds.end.x - bounds.position.x + 1
	var r_count := bounds.end.y - bounds.position.y + 1
	var max_candidate_count := maxi(0, q_count * r_count)
	_candidate_hex_count = max_candidate_count
	_visible_centers.resize(max_candidate_count)
	_visible_coords.resize(max_candidate_count)
	_visible_coord_lookup.clear()

	var visible_index := 0
	for q in range(bounds.position.x, bounds.end.x + 1):
		for r in range(bounds.position.y, bounds.end.y + 1):
			var coord := Vector2i(q, r)
			var center: Vector2 = HexGridMath.axial_to_world(coord, hex_radius)
			if not _is_inside_map(coord):
				_culled_by_map_count += 1
				continue
			if not _hex_rect_intersects_view(center, visible_rect):
				_culled_by_view_count += 1
				continue

			_visible_centers[visible_index] = center
			_visible_coords[visible_index] = coord
			_visible_coord_lookup[coord] = true
			visible_index += 1
			_visible_hex_count += 1
			_drawn_hex_count += 1

	_visible_centers.resize(visible_index)
	_visible_coords.resize(visible_index)


func _build_grid_lines_from_visible_cells() -> void:
	_grid_line_points.resize(_visible_coords.size() * 12)

	var point_index := 0
	for i in range(_visible_coords.size()):
		var coord: Vector2i = _visible_coords[i]
		var center: Vector2 = _visible_centers[i]
		for direction_index in range(6):
			var neighbor: Vector2i = coord + HexGridMath.direction(direction_index)
			if _visible_coord_lookup.has(neighbor) and _is_coord_before(neighbor, coord):
				continue

			var edge_index := 5 - direction_index
			_write_edge_line(center, edge_index, point_index)
			point_index += 2

	_line_point_count = point_index
	_grid_line_points.resize(_line_point_count)


func _write_edge_line(center: Vector2, edge_index: int, point_index: int) -> void:
	_grid_line_points[point_index] = center + _base_polygon[edge_index]
	_grid_line_points[point_index + 1] = center + _base_polygon[(edge_index + 1) % 6]


func _is_coord_before(a: Vector2i, b: Vector2i) -> bool:
	if a.x == b.x:
		return a.y < b.y
	return a.x < b.x


func _should_antialias_grid_lines() -> bool:
	if grid_line_antialiased:
		return true
	return grid_line_auto_antialias and _line_point_count <= grid_antialias_line_point_limit


func _draw_owned_cells(visible_rect: Rect2) -> void:
	if _owned_cells.is_empty() or _base_polygon.size() != 6:
		return

	for coord in _owned_cells.keys():
		var center: Vector2 = HexGridMath.axial_to_world(coord, hex_radius)
		if not _hex_rect_intersects_view(center, visible_rect):
			continue

		var colony_id := int(_owned_cells[coord])
		var color: Color = _colony_colors.get(colony_id, default_colony_color)
		for point_index in range(6):
			_scratch_polygon[point_index] = center + _base_polygon[point_index]

		draw_colored_polygon(_scratch_polygon, color)
		_owned_cells_drawn += 1
		_draw_call_estimate += 1


func _draw_overview_map() -> void:
	_draw_overview_fill()
	_draw_debug_axis_lines()


func _draw_simple_map() -> void:
	_draw_overview_fill()
	_draw_debug_axis_lines()


func _draw_overview_fill() -> void:
	_draw_map_outline()


func _draw_map_outline() -> void:
	if _map_outline_segments.is_empty():
		return

	draw_multiline(
		_map_outline_segments,
		outline_color,
		_get_screen_stable_line_width(map_outline_screen_width),
		grid_line_antialiased
	)
	_draw_call_estimate += 1


func _draw_debug_axis_lines() -> void:
	if not debug_axis_visible:
		return

	for direction_index in [0, 1, 2]:
		var start: Vector2 = HexGridMath.axial_to_world(
			HexGridMath.direction(direction_index + 3) * map_radius,
			hex_radius
		)
		var end: Vector2 = HexGridMath.axial_to_world(
			HexGridMath.direction(direction_index) * map_radius,
			hex_radius
		)
		draw_line(start, end, axis_color, 2.0, false)
		_draw_call_estimate += 1


func _is_inside_map(coord: Vector2i) -> bool:
	return HexGridMath.distance(coord, Vector2i.ZERO) <= map_radius


func _hex_rect_intersects_view(center: Vector2, visible_rect: Rect2) -> bool:
	var hex_extent := Vector2.ONE * hex_radius
	return Rect2(center - hex_extent, hex_extent * 2.0).intersects(visible_rect)


func _build_hex_polygon_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	points.resize(6)
	for i in range(6):
		var angle := deg_to_rad(30.0 + 60.0 * float(i))
		points[i] = Vector2(cos(angle), sin(angle)) * hex_radius
	return points


func _build_map_outline_segments() -> PackedVector2Array:
	var segments := PackedVector2Array()
	if _base_polygon.size() != 6 or _hexes.is_empty():
		return segments

	var coord_lookup := {}
	for coord in _hexes:
		coord_lookup[coord] = true

	for coord in _hexes:
		var center: Vector2 = HexGridMath.axial_to_world(coord, hex_radius)
		for direction_index in range(6):
			var neighbor: Vector2i = coord + HexGridMath.direction(direction_index)
			if coord_lookup.has(neighbor):
				continue

			var edge_index := 5 - direction_index
			segments.append(center + _base_polygon[edge_index])
			segments.append(center + _base_polygon[(edge_index + 1) % 6])

	return segments


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


func _get_screen_stable_line_width(screen_width: float) -> float:
	return screen_width / max(_get_camera_zoom(), 0.001)


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


func _get_visible_local_rect() -> Rect2:
	var rect := _get_visible_world_rect()

	_visible_corners[0] = to_local(rect.position)
	_visible_corners[1] = to_local(rect.position + Vector2(rect.size.x, 0.0))
	_visible_corners[2] = to_local(rect.position + rect.size)
	_visible_corners[3] = to_local(rect.position + Vector2(0.0, rect.size.y))

	var min_corner := _visible_corners[0]
	var max_corner := _visible_corners[0]
	for corner in _visible_corners:
		min_corner = min_corner.min(corner)
		max_corner = max_corner.max(corner)

	return Rect2(min_corner, max_corner - min_corner)


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


func _elapsed_ms(start_usec: int) -> float:
	return float(Time.get_ticks_usec() - start_usec) / 1000.0
