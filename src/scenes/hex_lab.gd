extends Node2D

const TerritorySim = preload("res://src/sim/territory_sim.gd")
const TEST_COLONY_ID := 1
const TEST_COLONY_START := Vector2i.ZERO

@export var camera_base_speed := 700.0
@export var camera_fast_multiplier := 3.0
@export var zoom_min := 0.25
@export var zoom_max := 3.0
@export var zoom_step_factor := 1.15
@export var zoom_smoothing := 14.0
@export var zoom_snap_tolerance := 0.005
@export var auto_step_interval := 0.25

@onready var _renderer := $HexMapRenderer
@onready var _camera: Camera2D = $Camera2D
@onready var _debug_overlay: Node = $DebugOverlay
@onready var _stats_label: Label = $HUD/StatsLabel

var _sim := TerritorySim.new()
var _colony_colors: Dictionary = {
	TEST_COLONY_ID: Color(0.1, 0.36, 1.0, 0.45),
}
var _auto_step_elapsed := 0.0
var _target_zoom := 1.0
var _middle_dragging := false
var _last_camera_position := Vector2.INF
var _last_camera_zoom := Vector2.INF
var _last_renderer_lod := ""


func _ready() -> void:
	_camera.make_current()
	_target_zoom = _camera.zoom.x
	_initialize_sim()
	_debug_overlay.register_provider("renderer", _renderer)
	_debug_overlay.register_provider("simulation", _sim)
	_renderer.queue_redraw()


func _process(delta: float) -> void:
	_step_simulation(delta)
	_handle_keyboard_pan(delta)
	_smooth_zoom(delta)
	_redraw_when_camera_changes()
	var frame_ms := delta * 1000.0
	_debug_overlay.sample_frame(frame_ms)
	_update_hud(frame_ms)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _middle_dragging:
		_camera.position -= event.relative / _camera.zoom
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_camera.position = Vector2.ZERO
			_target_zoom = 1.0
			_camera.zoom = Vector2.ONE
			_renderer.queue_redraw()
		elif event.keycode == KEY_G:
			_renderer.grid_visible = not _renderer.grid_visible
		elif event.keycode == KEY_X:
			_renderer.debug_axis_visible = not _renderer.debug_axis_visible
		elif event.keycode == KEY_H:
			_debug_overlay.toggle_detail_mode()
		elif event.keycode == KEY_R:
			_reset_sim()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_set_target_zoom(_target_zoom * zoom_step_factor)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_set_target_zoom(_target_zoom / zoom_step_factor)
	elif event.button_index == MOUSE_BUTTON_MIDDLE:
		_middle_dragging = event.pressed


func _handle_keyboard_pan(delta: float) -> void:
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y += 1.0

	if input == Vector2.ZERO:
		return

	var speed := camera_base_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= camera_fast_multiplier
	_camera.position += input.normalized() * speed * delta / _camera.zoom.x


func _smooth_zoom(delta: float) -> void:
	var current := _camera.zoom.x
	if absf(current - _target_zoom) <= zoom_snap_tolerance:
		if not is_equal_approx(current, _target_zoom):
			_camera.zoom = Vector2.ONE * _target_zoom
		return

	var weight := 1.0 - exp(-zoom_smoothing * delta)
	var next_zoom := lerpf(current, _target_zoom, weight)
	_camera.zoom = Vector2.ONE * next_zoom


func _set_target_zoom(value: float) -> void:
	_target_zoom = clampf(value, zoom_min, zoom_max)


func _initialize_sim() -> void:
	_sim.configure(_renderer.map_radius)
	_sim.spawn_colony(TEST_COLONY_ID, TEST_COLONY_START)
	_apply_sim_snapshot()


func _reset_sim() -> void:
	_auto_step_elapsed = 0.0
	_sim.reset()
	_apply_sim_snapshot()


func _step_simulation(delta: float) -> void:
	_auto_step_elapsed += delta
	if _auto_step_elapsed < auto_step_interval:
		return

	_auto_step_elapsed = 0.0
	if _sim.step_colony(TEST_COLONY_ID):
		_apply_sim_snapshot()


func _apply_sim_snapshot() -> void:
	_renderer.set_territory_snapshot(_sim.get_render_snapshot(), _colony_colors)


func _redraw_when_camera_changes() -> void:
	var current_lod: String = _renderer.get_current_lod_mode()
	var lod_changed: bool = current_lod != _last_renderer_lod
	if (
		_camera.position == _last_camera_position
		and _camera.zoom == _last_camera_zoom
		and not lod_changed
	):
		return

	_last_camera_position = _camera.position
	_last_camera_zoom = _camera.zoom
	_last_renderer_lod = current_lod

	if lod_changed or _renderer.needs_camera_redraw():
		_renderer.queue_redraw()


func _update_hud(frame_ms: float) -> void:
	var metrics: Dictionary = _debug_overlay.get_provider_metrics("renderer")
	var sim_metrics: Dictionary = _debug_overlay.get_provider_metrics("simulation")
	var overlay_metrics: Dictionary = _debug_overlay.get_debug_metrics()
	var frame_stats: Dictionary = overlay_metrics["frame_ms"]
	var draw_stats: Dictionary = overlay_metrics["renderer_draw_ms"]
	var grid_status := "off"
	if metrics["grid_visible"]:
		grid_status = "drawn" if metrics["cell_grid_drawn"] else "hidden by LOD"
	var aa_status := "on" if metrics["grid_line_effective_antialiased"] else "off"
	if metrics["grid_line_auto_antialias"] and not metrics["grid_line_antialiased"]:
		aa_status = "auto-on" if metrics["grid_line_effective_antialiased"] else "auto-off"

	var text := (
		"Teritro Hex Lab\n"
		+ "Radius: %d (%d cells)\n" % [_renderer.map_radius, _renderer.get_total_hex_count()]
		+ "Sim: colonies %d | owned %d | placements %d | stalled %d\n"
		% [
			sim_metrics["colony_count"],
			sim_metrics["owned_cells_total"],
			sim_metrics["placements_total"],
			sim_metrics["stalled_colonies"],
		]
		+ "LOD: %s | Visible: %d | Drawn: %d\n"
		% [metrics["lod"], metrics["visible"], metrics["drawn"]]
		+ "Candidates: %d | Cull M/V: %d/%d | Lines: %d\n"
		% [
			metrics["candidates"],
			metrics["culled_map"],
			metrics["culled_view"],
			metrics["line_points"],
		]
		+ "Draw calls: %d | Draw: %.2f ms | Submit: %.2f ms\n"
		% [metrics["draw_calls"], metrics["draw_ms"], metrics["submit_ms"]]
		+ "Zoom: %.2fx | Grid: %s | Axis: %s | HUD: %s\n"
		% [
			_camera.zoom.x,
			grid_status,
			"on" if metrics["debug_axis_visible"] else "off",
			_debug_overlay.get_detail_mode_label(),
		]
		+ "FPS: %d / %.2f ms | 60f avg/max: %.2f/%.2f ms\n"
		% [Engine.get_frames_per_second(), frame_ms, frame_stats["avg"], frame_stats["max"]]
	)

	if _debug_overlay.is_detailed():
		text += (
			"Sim step: candidates %d | valid %d | rejected %d | checks %d | %.3f ms\n"
			% [
				sim_metrics["candidate_count_last_step"],
				sim_metrics["valid_candidates_last_step"],
				sim_metrics["rejected_candidates_last_step"],
				sim_metrics["neighbor_checks_last_step"],
				sim_metrics["placement_validation_ms"],
			]
			+ "Sim rejects: straight %d | occupied %d | out %d | changed %d\n"
			% [
				sim_metrics["rejected_straight_last_step"],
				sim_metrics["rejected_occupied_last_step"],
				sim_metrics["rejected_out_of_bounds_last_step"],
				sim_metrics["changed_cells_last_step"],
			]
			+ "Phases: bounds %.2f | candidates %.2f | lines %.2f | submit %.2f\n"
			% [
				metrics["bounds_ms"],
				metrics["candidate_ms"],
				metrics["line_build_ms"],
				metrics["submit_ms"],
			]
			+ "Draw 60f min/avg/max: %.2f / %.2f / %.2f ms | AA: %s\n"
			% [
				draw_stats["min"],
				draw_stats["avg"],
				draw_stats["max"],
				aa_status,
			]
		)

	text += (
		"WASD/Arrows pan | Shift fast | MMB drag\n"
		+ "Mouse wheel zoom | G grid | X axes | H HUD | C camera | R sim"
	)

	_stats_label.text = text
