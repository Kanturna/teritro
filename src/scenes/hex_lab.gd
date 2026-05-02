extends Node2D

@export var camera_base_speed := 700.0
@export var camera_fast_multiplier := 3.0
@export var zoom_min := 0.25
@export var zoom_max := 3.0
@export var zoom_step_factor := 1.15
@export var zoom_smoothing := 14.0

@onready var _renderer := $HexMapRenderer
@onready var _camera: Camera2D = $Camera2D
@onready var _stats_label: Label = $HUD/StatsLabel

var _target_zoom := 1.0
var _middle_dragging := false
var _last_camera_position := Vector2.INF
var _last_camera_zoom := Vector2.INF


func _ready() -> void:
	_camera.make_current()
	_target_zoom = _camera.zoom.x
	_renderer.queue_redraw()


func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)
	_smooth_zoom(delta)
	_redraw_when_camera_changes()
	_update_hud(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _middle_dragging:
		_camera.position -= event.relative / _camera.zoom
		_renderer.queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_camera.position = Vector2.ZERO
			_target_zoom = 1.0
			_camera.zoom = Vector2.ONE
			_renderer.queue_redraw()
		elif event.keycode == KEY_G:
			_renderer.grid_visible = not _renderer.grid_visible


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
	if is_equal_approx(current, _target_zoom):
		return

	var weight := 1.0 - exp(-zoom_smoothing * delta)
	var next_zoom := lerpf(current, _target_zoom, weight)
	_camera.zoom = Vector2.ONE * next_zoom


func _set_target_zoom(value: float) -> void:
	_target_zoom = clampf(value, zoom_min, zoom_max)


func _redraw_when_camera_changes() -> void:
	if _camera.position == _last_camera_position and _camera.zoom == _last_camera_zoom:
		return
	_last_camera_position = _camera.position
	_last_camera_zoom = _camera.zoom
	_renderer.queue_redraw()


func _update_hud(delta: float) -> void:
	var frame_ms := delta * 1000.0
	var metrics: Dictionary = _renderer.get_debug_metrics()
	var grid_status := "off"
	if metrics["grid_visible"]:
		grid_status = "drawn" if metrics["cell_grid_drawn"] else "hidden by LOD"

	_stats_label.text = (
		"Teritro Hex Lab\n"
		+ "Radius: %d (%d cells)\n" % [_renderer.map_radius, _renderer.get_total_hex_count()]
		+ "LOD: %s | Visible: %d | Drawn: %d\n"
		% [metrics["lod"], metrics["visible"], metrics["drawn"]]
		+ "Candidates: %d | Draw calls: %d | Draw: %.2f ms\n"
		% [metrics["candidates"], metrics["draw_calls"], metrics["draw_ms"]]
		+ "Zoom: %.2fx | Grid: %s\n" % [_camera.zoom.x, grid_status]
		+ "FPS: %d / %.2f ms\n" % [Engine.get_frames_per_second(), frame_ms]
		+ "WASD/Arrows pan | Shift fast | MMB drag\n"
		+ "Mouse wheel zoom | G grid | C reset"
	)
