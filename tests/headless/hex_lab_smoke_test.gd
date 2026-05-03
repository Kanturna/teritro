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
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE

	_assert_eq(debug_overlay.has_provider("simulation"), true, "simulation provider registered")
	_assert_eq(renderer.get_total_hex_count(), 19441, "radius 80 total hex count")
	_assert_eq(renderer.get_child_count(), 0, "renderer does not create child nodes per hex")
	_assert_eq(renderer.get_debug_metrics()["owned_cells_total"], 1, "renderer receives starter snapshot")
	_assert_true(
		renderer.estimate_visible_hex_count() < 2800,
		"default zoom visible hex count below 2800 with edge coverage, got %d"
		% renderer.estimate_visible_hex_count()
	)
	_assert_eq(renderer.get_current_lod_mode(), "full", "default zoom LOD")
	_assert_eq(renderer.will_draw_cell_grid(), true, "default zoom draws cell grid")
	_assert_eq(renderer.get_debug_metrics()["debug_axis_visible"], false, "debug axes hidden by default")
	_assert_eq(renderer.get_debug_metrics()["grid_line_antialiased"], false, "grid lines antialiasing off by default")

	camera.zoom = Vector2.ONE * 0.6
	_assert_eq(renderer.get_current_lod_mode(), "simple", "mid zoom uses simple LOD")
	_assert_eq(renderer.will_draw_cell_grid(), false, "mid zoom hides cell grid by LOD")

	camera.zoom = Vector2.ONE * 0.25
	_assert_eq(renderer.get_current_lod_mode(), "overview", "min zoom uses overview LOD")
	_assert_eq(renderer.will_draw_cell_grid(), false, "min zoom hides cell grid by LOD")

	renderer.grid_visible = false
	_assert_eq(renderer.get_debug_metrics()["grid_visible"], false, "grid visibility toggle off")
	_assert_eq(renderer.will_draw_cell_grid(), false, "hidden grid does not draw cell grid")

	scene._process(0.26)
	await process_frame
	var sim_metrics: Dictionary = debug_overlay.get_provider_metrics("simulation")
	_assert_true(sim_metrics["owned_cells_total"] > 1, "auto-step expands colony")

	_send_key(scene, KEY_R)
	await process_frame
	sim_metrics = debug_overlay.get_provider_metrics("simulation")
	_assert_eq(sim_metrics["owned_cells_total"], 1, "R reset restores starter ownership")
	_assert_eq(sim_metrics["placements_total"], 0, "R reset clears placements")
	_assert_eq(renderer.get_debug_metrics()["owned_cells_total"], 1, "R reset updates renderer snapshot")

	if _failures.is_empty():
		print("Hex lab smoke tests passed.")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s, got %s" % [label, expected, actual])


func _assert_true(condition: bool, label: String) -> void:
	if not condition:
		_failures.append("%s: expected true" % label)


func _send_key(target: Node, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	event.echo = false
	target._unhandled_input(event)
