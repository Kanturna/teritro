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
		"grid_line_antialiased",
	]:
		_assert_eq(metrics.has(key), true, "renderer metric key %s" % key)

	_assert_eq(metrics["debug_axis_visible"], false, "debug axes hidden by default")
	_send_key(scene, KEY_X)
	_assert_eq(renderer.get_debug_metrics()["debug_axis_visible"], true, "X toggles debug axes")

	_assert_eq(renderer.get_debug_metrics()["grid_visible"], true, "grid visible by default")
	_send_key(scene, KEY_G)
	_assert_eq(renderer.get_debug_metrics()["grid_visible"], false, "G toggles grid")
	_send_key(scene, KEY_G)
	_assert_eq(renderer.get_debug_metrics()["grid_visible"], true, "G toggles grid back on")

	camera.zoom = Vector2.ONE
	_assert_eq(renderer.get_current_lod_mode(), "full", "default zoom LOD")

	camera.zoom = Vector2.ONE * 0.6
	_assert_eq(renderer.get_current_lod_mode(), "full", "mid zoom keeps full grid")
	_assert_eq(renderer.will_draw_cell_grid(), true, "mid zoom keeps cell grid visible")

	camera.zoom = Vector2.ONE * 0.25
	_assert_eq(renderer.get_current_lod_mode(), "full", "min zoom keeps full grid")
	_assert_eq(renderer.will_draw_cell_grid(), true, "min zoom keeps cell grid visible")

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
