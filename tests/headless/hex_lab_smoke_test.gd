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
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE

	_assert_eq(debug_overlay.has_provider("simulation"), true, "simulation provider registered")
	_assert_eq(renderer.get_total_hex_count(), 19441, "radius 80 total hex count")
	_assert_eq(renderer.get_child_count(), 1, "renderer has one owned-cell batch helper")
	_assert_eq(renderer.get_owned_cells_batch().name, "OwnedCellsBatch", "owned-cell batch helper name")
	_assert_eq(renderer.get_debug_metrics()["owned_cells_total"], 1, "renderer receives starter snapshot")
	_assert_eq(renderer.get_debug_metrics()["owned_batch_instances"], 1, "renderer batches starter ownership")
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

	_send_key(scene, KEY_P)
	scene._process(0.016)
	await process_frame
	var overlay_metrics: Dictionary = debug_overlay.get_debug_metrics()
	_assert_eq(overlay_metrics["last_snapshot_status"], "saved", "P saves debug snapshot")
	_assert_true(
		str(overlay_metrics["last_snapshot_path"]).begins_with("user://debug_snapshots/"),
		"P snapshot uses user path"
	)
	_assert_true(
		FileAccess.file_exists(overlay_metrics["last_snapshot_path"]),
		"P snapshot file exists"
	)
	_remove_snapshot_file(overlay_metrics["last_snapshot_path"])
	var label: Label = scene.get_node("HUD/StatsLabel")
	_assert_true(label.text.contains("P snapshot"), "HUD lists snapshot hotkey")
	_assert_true(label.text.contains("Snapshot saved:"), "HUD confirms snapshot save")

	var sim = scene._sim
	var center := Vector2i(3, 0)
	var ring := _ring_cells(center)
	var closing_cell: Vector2i = ring[0]
	var owned := [Vector2i.ZERO]
	for cell in ring:
		if cell != closing_cell:
			owned.append(cell)
	_apply_owned_cells(sim, owned, owned[0], 0)
	sim._place_cell(sim.colonies[1], closing_cell, 0)
	scene._apply_sim_snapshot()
	await process_frame
	sim_metrics = debug_overlay.get_provider_metrics("simulation")
	_assert_eq(sim_metrics["enclosure_filled_cells_last_step"], 1, "scene sim fills enclosure")
	_assert_eq(renderer.get_debug_metrics()["owned_cells_total"], owned.size() + 2, "renderer receives filled snapshot")
	_assert_eq(
		renderer.get_debug_metrics()["owned_batch_instances"],
		owned.size() + 2,
		"renderer batches filled snapshot"
	)

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


func _ring_cells(center: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for direction_index in range(6):
		cells.append(center + HexGridMath.direction(direction_index))
	return cells


func _apply_owned_cells(
	sim,
	cells: Array,
	last_placed_cell: Vector2i,
	last_placement_direction: int
) -> void:
	var colony = sim.colonies[1]
	sim.cell_owners.clear()
	colony.owned_cells.clear()

	for cell in cells:
		colony.owned_cells[cell] = true
		sim.cell_owners[cell] = colony.id

	colony.last_placed_cell = last_placed_cell
	colony.last_placement_direction = last_placement_direction
	colony.placements_total = maxi(0, cells.size() - 1)
	colony.stalled = false


func _remove_snapshot_file(path: String) -> void:
	var dir := DirAccess.open("user://debug_snapshots")
	if dir != null:
		dir.remove(path.get_file())
