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
var enclosure_scan_cell_limit := 3000
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
var _reanchor_attempts_last_step := 0
var _reanchors_last_step := 0
var _reanchors_total := 0
var _frontier_scan_cells_last_stall := 0
var _frontier_neighbor_checks_last_stall := 0
var _last_reanchor_distance := -1
var _stall_resolution_ms := 0.0
var _permanent_stalls_last_step := 0
var _permanent_stalls_total := 0
var _enclosure_regions_checked_last_step := 0
var _enclosure_visited_cells_last_step := 0
var _enclosure_filled_cells_last_step := 0
var _enclosure_aborted_regions_last_step := 0
var _enclosure_ms := 0.0
var _enclosures_total := 0
var _enclosure_filled_cells_total := 0


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
	_reanchors_total = 0
	_permanent_stalls_total = 0
	_enclosures_total = 0
	_enclosure_filled_cells_total = 0

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

	if _try_place_from_current_anchor(colony):
		_placement_validation_ms = _elapsed_ms(start_usec)
		return true

	var stall_start_usec := Time.get_ticks_usec()
	_reanchor_attempts_last_step = 1
	var anchor_result := _find_reanchor_cell(colony)
	_stall_resolution_ms = _elapsed_ms(stall_start_usec)

	if anchor_result["found"]:
		_reanchors_last_step = 1
		_reanchors_total += 1
		_last_reanchor_distance = anchor_result["distance"]
		colony.last_placed_cell = anchor_result["cell"]
		colony.last_placement_direction = UNDEFINED_DIRECTION
		colony.stalled = false

		if _try_place_from_current_anchor(colony):
			_placement_validation_ms = _elapsed_ms(start_usec)
			return true

	colony.stalled = true
	_permanent_stalls_last_step = 1
	_permanent_stalls_total += 1
	_placement_validation_ms = _elapsed_ms(start_usec)
	return false


func _try_place_from_current_anchor(colony: ColonyState) -> bool:
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
		return true

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
		"reanchor_attempts_last_step": _reanchor_attempts_last_step,
		"reanchors_last_step": _reanchors_last_step,
		"reanchors_total": _reanchors_total,
		"frontier_scan_cells_last_stall": _frontier_scan_cells_last_stall,
		"frontier_neighbor_checks_last_stall": _frontier_neighbor_checks_last_stall,
		"last_reanchor_distance": _last_reanchor_distance,
		"stall_resolution_ms": _stall_resolution_ms,
		"permanent_stalls_last_step": _permanent_stalls_last_step,
		"permanent_stalls_total": _permanent_stalls_total,
		"enclosure_regions_checked_last_step": _enclosure_regions_checked_last_step,
		"enclosure_visited_cells_last_step": _enclosure_visited_cells_last_step,
		"enclosure_filled_cells_last_step": _enclosure_filled_cells_last_step,
		"enclosure_aborted_regions_last_step": _enclosure_aborted_regions_last_step,
		"enclosure_ms": _enclosure_ms,
		"enclosures_total": _enclosures_total,
		"enclosure_filled_cells_total": _enclosure_filled_cells_total,
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
	_resolve_enclosures_after_placement(colony, coord)


func _resolve_enclosures_after_placement(colony: ColonyState, placed_cell: Vector2i) -> void:
	if _count_same_colony_neighbors(placed_cell, colony.id) < 2:
		return

	var start_usec := Time.get_ticks_usec()
	var step_enclosure_visited: Dictionary = {}

	for direction_index in range(6):
		var neighbor: Vector2i = placed_cell + HexGridMath.direction(direction_index)
		if not _is_inside_map(neighbor):
			continue
		if cell_owners.has(neighbor):
			continue
		if step_enclosure_visited.has(neighbor):
			continue

		_enclosure_regions_checked_last_step += 1
		var region_result := _scan_empty_region_for_enclosure(
			neighbor,
			colony.id,
			step_enclosure_visited
		)
		if region_result["aborted"]:
			_enclosure_aborted_regions_last_step += 1
			continue
		if not region_result["closed"]:
			continue

		_fill_enclosed_region(colony, region_result["cells"])

	_enclosure_ms = _elapsed_ms(start_usec)


func _count_same_colony_neighbors(coord: Vector2i, colony_id: int) -> int:
	var count := 0
	for direction_index in range(6):
		var neighbor: Vector2i = coord + HexGridMath.direction(direction_index)
		if int(cell_owners.get(neighbor, 0)) == colony_id:
			count += 1

	return count


func _scan_empty_region_for_enclosure(
	start: Vector2i,
	colony_id: int,
	step_enclosure_visited: Dictionary
) -> Dictionary:
	var queue: Array[Vector2i] = [start]
	var queue_index := 0
	var cells: Array[Vector2i] = []
	var closed := true
	var aborted := false
	step_enclosure_visited[start] = true

	while queue_index < queue.size():
		var cell := queue[queue_index]
		queue_index += 1
		cells.append(cell)
		_enclosure_visited_cells_last_step += 1

		if cells.size() > enclosure_scan_cell_limit:
			aborted = true
			closed = false
			break

		for direction_index in range(6):
			var neighbor: Vector2i = cell + HexGridMath.direction(direction_index)
			if not _is_inside_map(neighbor):
				closed = false
				continue

			var owner := int(cell_owners.get(neighbor, 0))
			if owner == colony_id:
				continue
			if owner != 0:
				closed = false
				continue
			if step_enclosure_visited.has(neighbor):
				continue

			step_enclosure_visited[neighbor] = true
			queue.append(neighbor)

	return {
		"closed": closed,
		"aborted": aborted,
		"cells": cells,
	}


func _fill_enclosed_region(colony: ColonyState, cells: Array[Vector2i]) -> void:
	if cells.is_empty():
		return

	for cell in cells:
		colony.owned_cells[cell] = true
		cell_owners[cell] = colony.id

	_enclosure_filled_cells_last_step += cells.size()
	_enclosure_filled_cells_total += cells.size()
	_enclosures_total += 1
	_changed_cells_last_step += cells.size()


func _find_reanchor_cell(colony: ColonyState) -> Dictionary:
	var has_best := false
	var best_cell := Vector2i.ZERO
	var best_distance := 0
	var origin := colony.last_placed_cell

	for owned_cell in colony.owned_cells.keys():
		var cell: Vector2i = owned_cell
		_frontier_scan_cells_last_stall += 1
		if not _has_free_neighbor(cell):
			continue

		var distance := HexGridMath.distance(origin, cell)
		if (
			not has_best
			or distance < best_distance
			or (
				distance == best_distance
				and (cell.x < best_cell.x or (cell.x == best_cell.x and cell.y < best_cell.y))
			)
		):
			has_best = true
			best_cell = cell
			best_distance = distance

	return {
		"found": has_best,
		"cell": best_cell,
		"distance": best_distance,
	}


func _has_free_neighbor(coord: Vector2i) -> bool:
	for direction_index in range(6):
		_frontier_neighbor_checks_last_stall += 1
		var candidate: Vector2i = coord + HexGridMath.direction(direction_index)
		if _is_inside_map(candidate) and not cell_owners.has(candidate):
			return true

	return false


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
	_reanchor_attempts_last_step = 0
	_reanchors_last_step = 0
	_frontier_scan_cells_last_stall = 0
	_frontier_neighbor_checks_last_stall = 0
	_last_reanchor_distance = -1
	_stall_resolution_ms = 0.0
	_permanent_stalls_last_step = 0
	_enclosure_regions_checked_last_step = 0
	_enclosure_visited_cells_last_step = 0
	_enclosure_filled_cells_last_step = 0
	_enclosure_aborted_regions_last_step = 0
	_enclosure_ms = 0.0


func _elapsed_ms(start_usec: int) -> float:
	return float(Time.get_ticks_usec() - start_usec) / 1000.0
