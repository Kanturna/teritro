extends RefCounted
class_name TerritorySim

const HexGridMath = preload("res://src/core/hex/hex_grid_math.gd")

const UNDEFINED_DIRECTION := -1


class ColonyState:
	var id: int
	var starter_cell: Vector2i
	var last_placed_cell: Vector2i
	var last_placement_direction := -1
	var owned_cells: Dictionary = {}
	var placements_total := 0
	var stalled := false

	func _init(colony_id: int, starter: Vector2i) -> void:
		id = colony_id
		starter_cell = starter
		reset_to_starter()

	func reset_to_starter() -> void:
		last_placed_cell = starter_cell
		last_placement_direction = -1
		owned_cells.clear()
		owned_cells[starter_cell] = true
		placements_total = 0
		stalled = false


var map_radius := 80
var cell_owners: Dictionary = {}
var colonies: Dictionary = {}

var _spawn_configs: Array[Dictionary] = []
var _candidate_count_last_step := 0
var _valid_candidates_last_step := 0
var _rejected_candidates_last_step := 0
var _rejected_straight_last_step := 0
var _rejected_occupied_last_step := 0
var _rejected_out_of_bounds_last_step := 0
var _neighbor_checks_last_step := 0
var _placement_validation_ms := 0.0
var _changed_cells_last_step := 0


func configure(new_map_radius: int) -> void:
	map_radius = maxi(0, new_map_radius)
	reset()


func spawn_colony(colony_id: int, starter: Vector2i) -> bool:
	return _spawn_colony_internal(colony_id, starter, true)


func reset() -> void:
	var configs := _spawn_configs.duplicate(true)
	cell_owners.clear()
	colonies.clear()
	_reset_step_metrics()

	for config in configs:
		_spawn_colony_internal(config["id"], config["starter"], false)


func step_colony(colony_id: int) -> bool:
	_reset_step_metrics()
	var start_usec := Time.get_ticks_usec()

	if not colonies.has(colony_id):
		_placement_validation_ms = _elapsed_ms(start_usec)
		return false

	var colony: ColonyState = colonies[colony_id]
	if colony.stalled:
		_placement_validation_ms = _elapsed_ms(start_usec)
		return false

	for direction_index in range(6):
		_candidate_count_last_step += 1
		_neighbor_checks_last_step += 1

		var candidate: Vector2i = colony.last_placed_cell + HexGridMath.direction(direction_index)
		if not _is_inside_map(candidate):
			_rejected_candidates_last_step += 1
			_rejected_out_of_bounds_last_step += 1
			continue

		if (
			colony.last_placement_direction != UNDEFINED_DIRECTION
			and direction_index == colony.last_placement_direction
		):
			_rejected_candidates_last_step += 1
			_rejected_straight_last_step += 1
			continue

		if cell_owners.has(candidate):
			_rejected_candidates_last_step += 1
			_rejected_occupied_last_step += 1
			continue

		_valid_candidates_last_step += 1
		_place_cell(colony, candidate, direction_index)
		_placement_validation_ms = _elapsed_ms(start_usec)
		return true

	colony.stalled = true
	_placement_validation_ms = _elapsed_ms(start_usec)
	return false


func get_owner_at(coord: Vector2i) -> int:
	return int(cell_owners.get(coord, 0))


func get_colony_debug_state(colony_id: int) -> Dictionary:
	if not colonies.has(colony_id):
		return {}

	var colony: ColonyState = colonies[colony_id]
	return {
		"id": colony.id,
		"starter_cell": colony.starter_cell,
		"last_placed_cell": colony.last_placed_cell,
		"last_placement_direction": colony.last_placement_direction,
		"owned_cell_count": colony.owned_cells.size(),
		"placements_total": colony.placements_total,
		"stalled": colony.stalled,
	}


func get_render_snapshot() -> Dictionary:
	return {
		"cell_owners": cell_owners.duplicate(),
	}


func get_debug_metrics() -> Dictionary:
	var placements_total := 0
	var stalled_colonies := 0
	for colony in colonies.values():
		placements_total += colony.placements_total
		if colony.stalled:
			stalled_colonies += 1

	return {
		"colony_count": colonies.size(),
		"owned_cells_total": cell_owners.size(),
		"placements_total": placements_total,
		"candidate_count_last_step": _candidate_count_last_step,
		"valid_candidates_last_step": _valid_candidates_last_step,
		"rejected_candidates_last_step": _rejected_candidates_last_step,
		"rejected_straight_last_step": _rejected_straight_last_step,
		"rejected_occupied_last_step": _rejected_occupied_last_step,
		"rejected_out_of_bounds_last_step": _rejected_out_of_bounds_last_step,
		"neighbor_checks_last_step": _neighbor_checks_last_step,
		"placement_validation_ms": _placement_validation_ms,
		"changed_cells_last_step": _changed_cells_last_step,
		"stalled_colonies": stalled_colonies,
	}


func _spawn_colony_internal(colony_id: int, starter: Vector2i, remember: bool) -> bool:
	if colonies.has(colony_id):
		return false
	if not _is_inside_map(starter):
		return false
	if cell_owners.has(starter):
		return false

	var colony := ColonyState.new(colony_id, starter)
	colonies[colony_id] = colony
	cell_owners[starter] = colony_id

	if remember:
		_spawn_configs.append({
			"id": colony_id,
			"starter": starter,
		})

	return true


func _place_cell(colony: ColonyState, coord: Vector2i, direction_index: int) -> void:
	colony.last_placed_cell = coord
	colony.last_placement_direction = direction_index
	colony.owned_cells[coord] = true
	colony.placements_total += 1
	cell_owners[coord] = colony.id
	_changed_cells_last_step = 1


func _is_inside_map(coord: Vector2i) -> bool:
	return HexGridMath.distance(coord, Vector2i.ZERO) <= map_radius


func _reset_step_metrics() -> void:
	_candidate_count_last_step = 0
	_valid_candidates_last_step = 0
	_rejected_candidates_last_step = 0
	_rejected_straight_last_step = 0
	_rejected_occupied_last_step = 0
	_rejected_out_of_bounds_last_step = 0
	_neighbor_checks_last_step = 0
	_placement_validation_ms = 0.0
	_changed_cells_last_step = 0


func _elapsed_ms(start_usec: int) -> float:
	return float(Time.get_ticks_usec() - start_usec) / 1000.0
