extends SceneTree

const HexGridMath = preload("res://src/core/hex/hex_grid_math.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)

	var packed: PackedScene = load("res://scenes/hex_lab.tscn")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame

	var renderer: Node = scene.get_node("HexMapRenderer")
	var camera: Camera2D = scene.get_node("Camera2D")
	var debug_overlay: Node = scene.get_node("DebugOverlay")

	_assert_eq(debug_overlay.has_provider("renderer"), true, "renderer provider registered")
	_assert_eq(debug_overlay.has_provider("simulation"), true, "simulation provider registered")
	_assert_eq(debug_overlay.get_detail_mode_label(), "compact", "default HUD mode")
	debug_overlay.toggle_detail_mode()
	_assert_eq(debug_overlay.get_detail_mode_label(), "detailed", "HUD detail toggle")

	debug_overlay.sample_frame(16.0)
	debug_overlay.sample_frame(20.0)
	var overlay_metrics: Dictionary = debug_overlay.get_debug_metrics()
	var frame_stats: Dictionary = overlay_metrics["frame_ms"]
	_assert_eq(frame_stats["samples"], 2, "frame history sample count")
	_assert_eq(frame_stats["min"], 16.0, "frame history min")
	_assert_eq(frame_stats["max"], 20.0, "frame history max")
	_assert_eq(overlay_metrics.has("last_snapshot_path"), true, "overlay snapshot path metric")
	_assert_eq(overlay_metrics.has("last_snapshot_status"), true, "overlay snapshot status metric")

	var metrics: Dictionary = renderer.get_debug_metrics()
	for key in [
		"bounds_ms",
		"candidate_ms",
		"line_build_ms",
		"submit_ms",
		"line_points",
		"culled_map",
		"culled_view",
		"grid_line_screen_width",
		"map_outline_screen_width",
		"map_outline_segments",
		"grid_line_antialiased",
		"grid_line_auto_antialias",
		"grid_line_effective_antialiased",
		"grid_antialias_line_point_limit",
		"owned_cells_total",
		"owned_cells_drawn",
		"owned_render_mode",
		"owned_batch_instances",
		"owned_batch_rebuild_ms",
		"owned_batch_draw_calls",
		"grid_render_mode",
		"grid_chunk_size",
		"grid_chunks_total",
		"grid_chunks_visible",
		"grid_cache_line_points_total",
		"grid_visible_line_points",
		"grid_cache_rebuild_ms",
		"grid_hidden_reason",
	]:
		_assert_eq(metrics.has(key), true, "renderer metric key %s" % key)
	_assert_eq(metrics["map_outline_segments"], 966, "radius 80 map outline segment count")
	_assert_eq(metrics["owned_cells_total"], 1, "renderer has starter ownership snapshot")
	_assert_eq(metrics["owned_render_mode"], "multimesh", "owned cell render mode")
	_assert_eq(metrics["owned_batch_instances"], 1, "starter owned batch instances")
	_assert_eq(metrics["owned_batch_draw_calls"], 1, "starter owned batch draw call estimate")
	_assert_eq(metrics["grid_render_mode"], "chunked_lines", "grid render mode")
	_assert_eq(metrics["grid_chunk_size"], 16, "grid chunk size")
	_assert_true(metrics["grid_chunks_total"] > 0, "grid cache has chunks")
	_assert_eq(metrics["grid_cache_line_points_total"], 117612, "radius 80 unique grid line points")
	_assert_true(metrics["grid_cache_rebuild_ms"] <= 250.0, "grid cache rebuild under 250 ms")

	var sim_metrics: Dictionary = debug_overlay.get_provider_metrics("simulation")
	for key in [
		"colony_count",
		"owned_cells_total",
		"placements_total",
		"candidate_count_last_step",
		"valid_candidates_last_step",
		"rejected_candidates_last_step",
		"neighbor_checks_last_step",
		"placement_validation_ms",
		"stalled_colonies",
		"reanchor_attempts_last_step",
		"reanchors_last_step",
		"reanchors_total",
		"frontier_scan_cells_last_stall",
		"frontier_neighbor_checks_last_stall",
		"last_reanchor_distance",
		"stall_resolution_ms",
		"permanent_stalls_last_step",
		"permanent_stalls_total",
		"enclosure_regions_checked_last_step",
		"enclosure_visited_cells_last_step",
		"enclosure_filled_cells_last_step",
		"enclosure_aborted_regions_last_step",
		"enclosure_effective_scan_limit_last_step",
		"enclosure_ms",
		"enclosures_total",
		"enclosure_filled_cells_total",
	]:
		_assert_eq(sim_metrics.has(key), true, "simulation metric key %s" % key)
	_assert_eq(sim_metrics["colony_count"], 1, "simulation colony count")
	_assert_eq(sim_metrics["owned_cells_total"], 1, "simulation starter ownership count")

	_assert_eq(metrics["debug_axis_visible"], false, "debug axes hidden by default")
	_send_key(scene, KEY_X)
	_assert_eq(renderer.get_debug_metrics()["debug_axis_visible"], true, "X toggles debug axes")

	_assert_eq(renderer.get_debug_metrics()["grid_visible"], true, "grid visible by default")
	_send_key(scene, KEY_G)
	_assert_eq(renderer.get_debug_metrics()["grid_visible"], false, "G toggles grid")
	_send_key(scene, KEY_G)
	_assert_eq(renderer.get_debug_metrics()["grid_visible"], true, "G toggles grid back on")

	camera.zoom = Vector2.ONE
	renderer.queue_redraw()
	await process_frame
	metrics = renderer.get_debug_metrics()
	_assert_eq(renderer.get_current_lod_mode(), "full", "default zoom LOD")
	_assert_true(
		metrics["line_points"] > 0 and metrics["line_points"] <= metrics["grid_cache_line_points_total"],
		"full grid uses cached shared edges"
	)
	_assert_eq(metrics["grid_line_antialiased"], false, "manual grid antialiasing default")
	_assert_eq(metrics["grid_line_effective_antialiased"], true, "auto antialiasing activates under line-point limit")

	_assert_camera_redraw_matrix(renderer, camera)
	await _assert_owned_cell_batch_path(renderer, camera)
	_assert_multimesh_preserves_per_colony_color(renderer)
	await _assert_chunked_grid_cache(renderer, camera)
	_assert_grid_position_independence(renderer, camera)
	_assert_snapshot_roundtrip(scene, debug_overlay, camera)

	if _failures.is_empty():
		print("Hex debug metrics tests passed.")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)


func _send_key(target: Node, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.echo = false
	target._unhandled_input(event)


func _assert_camera_redraw_matrix(renderer: Node, camera: Camera2D) -> void:
	var cases := [
		{"zoom": 0.25, "grid": true, "lod": "overview", "redraw": false},
		{"zoom": 0.25, "grid": false, "lod": "overview", "redraw": false},
		{"zoom": 0.6, "grid": true, "lod": "simple", "redraw": false},
		{"zoom": 0.6, "grid": false, "lod": "simple", "redraw": false},
		{"zoom": 0.65, "grid": true, "lod": "simple", "redraw": false},
		{"zoom": 0.7, "grid": true, "lod": "full", "redraw": true},
		{"zoom": 0.7, "grid": false, "lod": "full", "redraw": false},
		{"zoom": 1.0, "grid": true, "lod": "full", "redraw": true},
		{"zoom": 1.0, "grid": false, "lod": "full", "redraw": false},
	]

	for test_case in cases:
		camera.zoom = Vector2.ONE * float(test_case["zoom"])
		renderer.grid_visible = bool(test_case["grid"])
		_assert_eq(
			renderer.get_current_lod_mode(),
			test_case["lod"],
			"LOD matrix zoom %.2f grid %s" % [test_case["zoom"], test_case["grid"]]
		)
		_assert_eq(
			renderer.needs_camera_redraw(),
			test_case["redraw"],
			"camera redraw matrix zoom %.2f grid %s" % [test_case["zoom"], test_case["grid"]]
		)


func _assert_owned_cell_batch_path(renderer: Node, camera: Camera2D) -> void:
	camera.zoom = Vector2.ONE
	renderer.grid_visible = false
	var child_count_before: int = renderer.get_child_count()
	var owners := _owned_cells_snapshot(13)
	renderer.set_territory_snapshot({"cell_owners": owners}, {1: Color(0.1, 0.36, 1.0, 0.45)})
	renderer.queue_redraw()
	await process_frame
	await process_frame

	var metrics: Dictionary = renderer.get_debug_metrics()
	_assert_eq(renderer.get_child_count(), child_count_before, "owned batch does not add per-cell nodes")
	_assert_eq(metrics["owned_cells_total"], owners.size(), "synthetic owned snapshot count")
	_assert_eq(metrics["owned_batch_instances"], owners.size(), "synthetic owned batch instance count")
	_assert_eq(metrics["owned_cells_drawn"], owners.size(), "owned cells drawn via batch metric")
	_assert_eq(metrics["owned_batch_draw_calls"], 1, "owned batch draw call remains one")
	_assert_true(metrics["draw_calls"] <= 5, "draw call estimate does not scale with owned cells")


func _assert_multimesh_preserves_per_colony_color(renderer: Node) -> void:
	var owners := {
		Vector2i(1, 0): 1,
		Vector2i(2, 0): 2,
	}
	var colors := {
		1: Color.RED,
		2: Color.BLUE,
	}
	renderer.set_territory_snapshot({"cell_owners": owners}, colors)

	var batch: MultiMeshInstance2D = renderer.get_owned_cells_batch()
	_assert_eq(batch.multimesh.instance_count, 2, "two-color batch instance count")
	_assert_true(
		renderer.get_owned_cell_instance_color(0) != renderer.get_owned_cell_instance_color(1),
		"per-colony instance colors are preserved"
	)


func _assert_chunked_grid_cache(renderer: Node, camera: Camera2D) -> void:
	camera.zoom = Vector2.ONE
	renderer.grid_visible = true
	camera.position = Vector2.ZERO
	_assert_eq(renderer.will_draw_cell_grid(), true, "default zoom draws chunked grid")
	var before_rebuild_ms: float = renderer.get_debug_metrics()["grid_cache_rebuild_ms"]
	renderer.queue_redraw()
	await process_frame

	var metrics: Dictionary = renderer.get_debug_metrics()
	_assert_eq(metrics["grid_render_mode"], "chunked_lines", "chunked grid metric")
	_assert_eq(metrics["grid_hidden_reason"], "none", "visible grid reason")
	_assert_true(metrics["grid_chunks_visible"] > 0, "visible grid chunks")
	_assert_true(metrics["grid_visible_line_points"] > 0, "visible grid line points")
	_assert_eq(metrics["line_points"], metrics["grid_visible_line_points"], "line points mirror visible chunk points")
	_assert_eq(metrics["visible"], 0, "chunked grid does not repurpose visible cell count")
	_assert_eq(metrics["drawn"], 0, "chunked grid does not repurpose drawn cell count")
	_assert_eq(metrics["candidates"], 0, "chunked grid does not repurpose candidate cell count")
	_assert_eq(metrics["line_build_ms"], 0.0, "camera draw does not rebuild line points")

	camera.position = Vector2(800.0, 600.0)
	renderer.queue_redraw()
	await process_frame
	metrics = renderer.get_debug_metrics()
	_assert_eq(metrics["grid_cache_rebuild_ms"], before_rebuild_ms, "camera pan does not rebuild grid cache")


func _assert_grid_position_independence(renderer: Node, camera: Camera2D) -> void:
	var positions := [
		Vector2.ZERO,
		Vector2(1600.0, 0.0),
		Vector2(-1600.0, 0.0),
		Vector2(0.0, 1600.0),
		Vector2(0.0, -1600.0),
	]
	for zoom in [1.0, 0.7]:
		var has_expected := false
		var expected_draw := false
		var expected_reason := ""
		for position in positions:
			camera.zoom = Vector2.ONE * zoom
			camera.position = position
			renderer.grid_visible = true
			var draw_grid: bool = renderer.will_draw_cell_grid()
			var reason: String = renderer.get_debug_metrics()["grid_hidden_reason"]
			if not has_expected:
				has_expected = true
				expected_draw = draw_grid
				expected_reason = reason
			_assert_eq(draw_grid, expected_draw, "grid position independence draw zoom %.2f" % zoom)
			_assert_eq(reason, expected_reason, "grid position independence reason zoom %.2f" % zoom)

	renderer.grid_visible = false
	_assert_eq(renderer.will_draw_cell_grid(), false, "hidden grid does not draw")
	_assert_eq(renderer.get_debug_metrics()["grid_hidden_reason"], "global_off", "hidden grid reason")

	renderer.grid_visible = true
	camera.zoom = Vector2.ONE * 0.6
	_assert_eq(renderer.will_draw_cell_grid(), false, "simple LOD hides grid")
	_assert_eq(renderer.get_debug_metrics()["grid_hidden_reason"], "zoom_lod", "simple LOD hidden reason")


func _assert_snapshot_roundtrip(scene: Node, debug_overlay: Node, camera: Camera2D) -> void:
	var sim = scene._sim
	sim.step_colony(1)
	var context := {
		"camera_position": camera.position,
		"camera_zoom": camera.zoom.x,
		"viewport_size": root.size,
		"grid_status": "test",
	}
	var snapshot: Dictionary = debug_overlay.capture_snapshot("roundtrip", context)
	_assert_eq(snapshot["version"], 1, "snapshot schema version")
	_assert_eq(snapshot["providers"].has("renderer"), true, "snapshot renderer provider")
	_assert_eq(snapshot["providers"].has("simulation"), true, "snapshot simulation provider")
	_assert_eq(
		snapshot["providers"]["renderer"]["grid_render_mode"],
		"chunked_lines",
		"snapshot preserves chunked grid mode"
	)
	_assert_eq(
		snapshot["providers"]["renderer"].has("full_grid_candidate_limit"),
		false,
		"snapshot no longer exposes grid candidate cap"
	)
	_assert_true(
		snapshot["providers"]["simulation"]["placements_total"] >= 1,
		"snapshot reflects real simulation state"
	)

	var json_text := JSON.stringify(snapshot)
	var parsed_direct = JSON.parse_string(json_text)
	_assert_eq(parsed_direct["version"], 1, "snapshot serializes to JSON")

	var path: String = debug_overlay.save_snapshot(snapshot)
	_assert_true(not path.is_empty(), "snapshot save path")
	_assert_true(path.begins_with("user://debug_snapshots/"), "snapshot saves under user path")
	_assert_true(FileAccess.file_exists(path), "snapshot file exists")

	var file_content := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(file_content)
	_assert_eq(parsed["version"], 1, "saved snapshot version")
	_assert_true(
		is_equal_approx(float(parsed["context"]["camera_zoom"]), float(context["camera_zoom"])),
		"saved snapshot camera zoom"
	)
	_assert_eq(parsed["providers"].has("renderer"), true, "saved snapshot renderer provider")
	_assert_eq(parsed["providers"].has("simulation"), true, "saved snapshot simulation provider")
	_assert_eq(
		parsed["providers"]["renderer"]["grid_render_mode"],
		"chunked_lines",
		"saved snapshot grid render mode"
	)
	_assert_eq(
		parsed["providers"]["renderer"].has("grid_hidden_reason"),
		true,
		"saved snapshot grid hidden reason"
	)
	_assert_true(
		parsed["providers"]["simulation"]["placements_total"] >= 1,
		"saved snapshot preserves simulation metrics"
	)
	_remove_snapshot_file(path)


func _owned_cells_snapshot(radius: int) -> Dictionary:
	var owners := {}
	for coord in HexGridMath.coords_in_radius(radius):
		owners[coord] = 1
	return owners


func _remove_snapshot_file(path: String) -> void:
	var dir := DirAccess.open("user://debug_snapshots")
	if dir != null:
		dir.remove(path.get_file())


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s, got %s" % [label, expected, actual])


func _assert_true(condition: bool, label: String) -> void:
	if not condition:
		_failures.append("%s: expected true" % label)
