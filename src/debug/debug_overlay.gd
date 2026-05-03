extends Node
class_name DebugOverlay

const HISTORY_SIZE := 60
const SNAPSHOT_SCHEMA_VERSION := 1
const SNAPSHOT_DIR := "user://debug_snapshots"

enum DetailMode {
	COMPACT,
	DETAILED,
}

var _providers: Dictionary = {}
var _detail_mode := DetailMode.COMPACT
var _frame_ms_history: Array[float] = []
var _renderer_draw_ms_history: Array[float] = []
var _last_snapshot_path := ""
var _last_snapshot_status := "none"


func register_provider(provider_name: String, provider: Object) -> void:
	_providers[provider_name] = provider


func has_provider(provider_name: String) -> bool:
	return _providers.has(provider_name)


func toggle_detail_mode() -> void:
	_detail_mode = DetailMode.DETAILED if _detail_mode == DetailMode.COMPACT else DetailMode.COMPACT


func get_detail_mode() -> int:
	return _detail_mode


func get_detail_mode_label() -> String:
	return "detailed" if _detail_mode == DetailMode.DETAILED else "compact"


func is_detailed() -> bool:
	return _detail_mode == DetailMode.DETAILED


func sample_frame(frame_ms: float) -> void:
	_push_sample(_frame_ms_history, frame_ms)

	var renderer_metrics := get_provider_metrics("renderer")
	if renderer_metrics.has("draw_ms"):
		_push_sample(_renderer_draw_ms_history, float(renderer_metrics["draw_ms"]))


func capture_snapshot(label: String, context: Dictionary) -> Dictionary:
	return {
		"version": SNAPSHOT_SCHEMA_VERSION,
		"label": label,
		"timestamp_unix": Time.get_unix_time_from_system(),
		"overlay": _make_json_safe(get_debug_metrics()),
		"providers": _capture_provider_metrics(),
		"context": _make_json_safe(context),
	}


func save_snapshot(snapshot: Dictionary) -> String:
	var dir_error := DirAccess.make_dir_recursive_absolute(SNAPSHOT_DIR)
	if dir_error != OK:
		_last_snapshot_path = ""
		_last_snapshot_status = "failed: mkdir %d" % dir_error
		return ""

	var label := _sanitize_label(str(snapshot.get("label", "snapshot")))
	var timestamp := int(snapshot.get("timestamp_unix", Time.get_unix_time_from_system()))
	var path := "%s/teritro_%s_%d_%d.json" % [
		SNAPSHOT_DIR,
		label,
		timestamp,
		Time.get_ticks_msec(),
	]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var open_error := FileAccess.get_open_error()
		_last_snapshot_path = ""
		_last_snapshot_status = "failed: open %d" % open_error
		return ""

	file.store_string(JSON.stringify(_make_json_safe(snapshot), "\t"))
	_last_snapshot_path = path
	_last_snapshot_status = "saved"
	return path


func get_provider_metrics(provider_name: String) -> Dictionary:
	if not _providers.has(provider_name):
		return {}

	var provider: Object = _providers[provider_name]
	if provider == null or not provider.has_method("get_debug_metrics"):
		return {}

	return provider.call("get_debug_metrics")


func get_debug_metrics() -> Dictionary:
	return {
		"detail_mode": get_detail_mode_label(),
		"frame_ms": _history_stats(_frame_ms_history),
		"renderer_draw_ms": _history_stats(_renderer_draw_ms_history),
		"providers": _providers.keys(),
		"last_snapshot_path": _last_snapshot_path,
		"last_snapshot_status": _last_snapshot_status,
	}


func _push_sample(history: Array[float], value: float) -> void:
	history.push_back(value)
	if history.size() > HISTORY_SIZE:
		history.pop_front()


func _history_stats(history: Array[float]) -> Dictionary:
	if history.is_empty():
		return {
			"samples": 0,
			"min": 0.0,
			"avg": 0.0,
			"max": 0.0,
		}

	var min_value := history[0]
	var max_value := history[0]
	var total := 0.0

	for value in history:
		min_value = min(min_value, value)
		max_value = max(max_value, value)
		total += value

	return {
		"samples": history.size(),
		"min": min_value,
		"avg": total / float(history.size()),
		"max": max_value,
	}


func _capture_provider_metrics() -> Dictionary:
	var metrics := {}
	for provider_name in _providers.keys():
		metrics[str(provider_name)] = _make_json_safe(get_provider_metrics(provider_name))
	return metrics


func _make_json_safe(value):
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		TYPE_STRING_NAME:
			return String(value)
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return [value.x, value.y]
		TYPE_COLOR:
			return [value.r, value.g, value.b, value.a]
		TYPE_DICTIONARY:
			var safe_dict := {}
			for key in value.keys():
				safe_dict[str(key)] = _make_json_safe(value[key])
			return safe_dict
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, \
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, \
		TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY:
			var safe_array := []
			for item in value:
				safe_array.append(_make_json_safe(item))
			return safe_array
		_:
			return str(value)


func _sanitize_label(label: String) -> String:
	var clean := label.strip_edges().to_lower()
	if clean.is_empty():
		return "snapshot"

	var result := ""
	for index in range(clean.length()):
		var character := clean[index]
		if character.is_valid_identifier() or character.is_valid_int():
			result += character
		elif character in ["-", "_"]:
			result += character
		else:
			result += "_"
	return result
