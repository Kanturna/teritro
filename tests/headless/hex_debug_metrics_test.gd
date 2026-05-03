extends SceneTree

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
	]:
		_assert_eq(metrics.has(key), true, "renderer metric key %s" % key)
	_assert_eq(metrics["map_outline_segments"], 966, "radius 80 map outline segment count")
	_assert_eq(metrics["owned_cells_total"], 1, "renderer has starter ownership snapshot")

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
		metrics["line_points"] > 0 and metrics["line_points"] < metrics["drawn"] * 12,
		"full grid uses deduplicated shared edges"
	)
	_assert_eq(metrics["grid_line_antialiased"], false, "manual grid antialiasing default")
	_assert_eq(metrics["grid_line_effective_antialiased"], true, "auto antialiasing activates under line-point limit")

	camera.zoom = Vector2.ONE * 0.6
	_assert_eq(renderer.get_current_lod_mode(), "simple", "mid zoom uses simple LOD")
	_assert_eq(renderer.will_draw_cell_grid(), false, "mid zoom hides cell grid by LOD")
	_assert_eq(renderer.needs_camera_redraw(), true, "owned cells redraw when panning in simple LOD")

	camera.zoom = Vector2.ONE * 0.25
	_assert_eq(renderer.get_current_lod_mode(), "overview", "min zoom uses overview LOD")
	_assert_eq(renderer.will_draw_cell_grid(), false, "min zoom hides cell grid by LOD")
	_assert_eq(renderer.needs_camera_redraw(), true, "owned cells redraw when panning in overview LOD")

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


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s, got %s" % [label, expected, actual])


func _assert_true(condition: bool, label: String) -> void:
	if not condition:
		_failures.append("%s: expected true" % label)
