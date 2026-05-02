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
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE

	_assert_eq(renderer.get_total_hex_count(), 19441, "radius 80 total hex count")
	_assert_eq(renderer.get_child_count(), 0, "renderer does not create child nodes per hex")
	_assert_true(
		renderer.estimate_visible_hex_count() < 2500,
		"default zoom visible hex count below 2500, got %d"
		% renderer.estimate_visible_hex_count()
	)
	_assert_eq(renderer.get_current_lod_mode(), "full", "default zoom LOD")

	camera.zoom = Vector2.ONE * 0.25
	_assert_eq(renderer.get_current_lod_mode(), "overview", "min zoom LOD")

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
