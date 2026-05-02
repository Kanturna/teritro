extends Node
class_name DebugOverlay

const HISTORY_SIZE := 60

enum DetailMode {
	COMPACT,
	DETAILED,
}

var _providers: Dictionary = {}
var _detail_mode := DetailMode.COMPACT
var _frame_ms_history: Array[float] = []
var _renderer_draw_ms_history: Array[float] = []


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
