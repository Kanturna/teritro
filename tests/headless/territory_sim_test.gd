extends SceneTree

const TerritorySim = preload("res://src/sim/territory_sim.gd")
const HexGridMath = preload("res://src/core/hex/hex_grid_math.gd")

var _failures: Array[String] = []


func _init() -> void:
	_test_spawn_and_first_step()
	_test_turn_rule_rejects_straight_continuation()
	_test_occupied_and_out_of_bounds_rejections()
	_test_stall_when_no_valid_neighbor()
	_test_reanchor_after_local_stall()
	_test_no_reanchor_without_stall()
	_test_reset_restores_starter_state()
	_test_reset_clears_reanchor_and_permanent_stall_totals()
	_test_reset_clears_enclosure_totals()
	_test_deterministic_sequence()
	_test_reanchor_sequence_is_deterministic()
	_test_one_cell_enclosure_fills()
	_test_multi_cell_enclosure_fills()
	_test_open_region_does_not_fill()
	_test_contested_region_does_not_fill()
	_test_normal_growth_skips_enclosure_scan()
	_test_enclosure_scan_cap_aborts()
	_test_sim_does_not_use_global_radius_scan()

	if _failures.is_empty():
		print("TerritorySim tests passed.")
		quit(0)
	else:
		for failure in _failures:
			printerr(failure)
		quit(1)


func _test_spawn_and_first_step() -> void:
	var sim := _new_sim(80)
	_assert_eq(sim.get_owner_at(Vector2i.ZERO), 1, "starter owner")
	_assert_eq(sim.get_debug_metrics()["owned_cells_total"], 1, "starter owned count")

	_assert_eq(sim.step_colony(1), true, "first step succeeds")
	var state: Dictionary = sim.get_colony_debug_state(1)
	_assert_eq(
		HexGridMath.distance(Vector2i.ZERO, state["last_placed_cell"]),
		1,
		"first step is adjacent"
	)
	_assert_eq(state["last_placement_direction"], 0, "first direction is deterministic")
	_assert_eq(sim.get_debug_metrics()["neighbor_checks_last_step"] <= 6, true, "first step max checks")


func _test_turn_rule_rejects_straight_continuation() -> void:
	var sim := _new_sim(80)
	_assert_eq(sim.step_colony(1), true, "first step before straight rejection")
	_assert_eq(sim.step_colony(1), true, "second step after straight rejection")

	var state: Dictionary = sim.get_colony_debug_state(1)
	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(state["last_placement_direction"], 1, "second direction turns")
	_assert_eq(metrics["rejected_straight_last_step"], 1, "straight candidate rejected")
	_assert_eq(metrics["neighbor_checks_last_step"], 2, "straight reject then first valid turn")


func _test_occupied_and_out_of_bounds_rejections() -> void:
	var sim := _new_sim(1)
	_assert_eq(sim.step_colony(1), true, "radius one step 1")
	_assert_eq(sim.step_colony(1), true, "radius one step 2")
	_assert_eq(sim.step_colony(1), true, "radius one step 3")
	_assert_eq(sim.step_colony(1), true, "radius one step 4")

	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(metrics["rejected_occupied_last_step"] > 0, true, "occupied candidate rejected")
	_assert_eq(metrics["rejected_out_of_bounds_last_step"] > 0, true, "out-of-bounds candidates rejected")
	_assert_eq(metrics["neighbor_checks_last_step"] <= 6, true, "occupied test max checks")


func _test_stall_when_no_valid_neighbor() -> void:
	var sim := _new_sim(0)
	_assert_eq(sim.step_colony(1), false, "radius zero cannot expand")

	var state: Dictionary = sim.get_colony_debug_state(1)
	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(state["stalled"], true, "colony stalls")
	_assert_eq(metrics["stalled_colonies"], 1, "stalled metric")
	_assert_eq(metrics["rejected_out_of_bounds_last_step"], 6, "all neighbors out of bounds")
	_assert_eq(metrics["neighbor_checks_last_step"], 6, "stall checks all neighbors")
	_assert_eq(metrics["permanent_stalls_last_step"], 1, "radius zero permanent stall")


func _test_reanchor_after_local_stall() -> void:
	var sim := _new_sim(3)
	var blocked_cells := _blocked_origin_cells()
	_apply_owned_cells(sim, blocked_cells, Vector2i.ZERO, 0)

	_assert_eq(sim.step_colony(1), true, "reanchor step succeeds")

	var state: Dictionary = sim.get_colony_debug_state(1)
	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(metrics["reanchor_attempts_last_step"], 1, "reanchor attempted after local stall")
	_assert_eq(metrics["reanchors_last_step"], 1, "reanchor succeeded")
	_assert_eq(metrics["reanchors_total"], 1, "reanchor total")
	_assert_eq(metrics["last_reanchor_distance"], 1, "nearest reanchor distance")
	_assert_eq(
		metrics["frontier_scan_cells_last_stall"] <= blocked_cells.size(),
		true,
		"reanchor scans only owned cells"
	)
	_assert_eq(
		metrics["frontier_neighbor_checks_last_stall"] <= blocked_cells.size() * 6,
		true,
		"reanchor checks at most six neighbors per owned cell"
	)
	_assert_eq(state["last_placed_cell"], Vector2i(-1, -1), "tie-break anchor places first free cell")
	_assert_eq(state["last_placement_direction"], 2, "direction reset allows first free direction")
	_assert_eq(state["stalled"], false, "reanchor clears stall")


func _test_no_reanchor_without_stall() -> void:
	var sim := _new_sim(80)
	for i in range(10):
		_assert_eq(sim.step_colony(1), true, "normal step %d succeeds" % i)
		var metrics: Dictionary = sim.get_debug_metrics()
		_assert_eq(metrics["reanchor_attempts_last_step"], 0, "normal step no reanchor attempt")
		_assert_eq(metrics["frontier_scan_cells_last_stall"], 0, "normal step no frontier scan")
		_assert_eq(metrics["reanchors_total"], 0, "normal steps do not reanchor")


func _test_reset_restores_starter_state() -> void:
	var sim := _new_sim(80)
	for _i in range(3):
		sim.step_colony(1)

	sim.reset()
	var state: Dictionary = sim.get_colony_debug_state(1)
	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(state["last_placed_cell"], Vector2i.ZERO, "reset last placed")
	_assert_eq(state["last_placement_direction"], TerritorySim.UNDEFINED_DIRECTION, "reset direction")
	_assert_eq(state["placements_total"], 0, "reset placements")
	_assert_eq(state["stalled"], false, "reset clears stall")
	_assert_eq(metrics["owned_cells_total"], 1, "reset owned count")
	_assert_eq(metrics["neighbor_checks_last_step"], 0, "reset clears step metrics")


func _test_reset_clears_reanchor_and_permanent_stall_totals() -> void:
	var reanchor_sim := _new_sim(3)
	_apply_owned_cells(reanchor_sim, _blocked_origin_cells(), Vector2i.ZERO, 0)
	_assert_eq(reanchor_sim.step_colony(1), true, "reset total test reanchor")
	_assert_eq(
		reanchor_sim.get_debug_metrics()["reanchors_total"],
		1,
		"reset total test has reanchor"
	)
	reanchor_sim.reset()
	_assert_eq(
		reanchor_sim.get_debug_metrics()["reanchors_total"],
		0,
		"reset clears reanchors total"
	)

	var stalled_sim := _new_sim(0)
	_assert_eq(stalled_sim.step_colony(1), false, "reset total test permanent stall")
	_assert_eq(
		stalled_sim.get_debug_metrics()["permanent_stalls_total"],
		1,
		"reset total test has permanent stall"
	)
	stalled_sim.reset()
	_assert_eq(
		stalled_sim.get_debug_metrics()["permanent_stalls_total"],
		0,
		"reset clears permanent stalls total"
	)


func _test_reset_clears_enclosure_totals() -> void:
	var sim := _new_sim(8)
	var center := Vector2i(3, 0)
	var ring := _ring_cells(center)
	var closing_cell: Vector2i = ring[0]
	var owned := [Vector2i.ZERO]
	owned.append_array(_without_cell(ring, closing_cell))
	_apply_owned_cells(sim, owned, owned[0], TerritorySim.UNDEFINED_DIRECTION)

	sim._place_cell(sim.colonies[1], closing_cell, 0)
	_assert_eq(sim.get_debug_metrics()["enclosures_total"], 1, "reset enclosure test has enclosure")
	_assert_eq(
		sim.get_debug_metrics()["enclosure_filled_cells_total"],
		1,
		"reset enclosure test has filled cell"
	)

	sim.reset()
	_assert_eq(sim.get_debug_metrics()["enclosures_total"], 0, "reset clears enclosures total")
	_assert_eq(
		sim.get_debug_metrics()["enclosure_filled_cells_total"],
		0,
		"reset clears enclosure filled cells total"
	)


func _test_deterministic_sequence() -> void:
	var sim_a := _new_sim(80)
	var sim_b := _new_sim(80)
	var sequence_a: Array[Vector2i] = []
	var sequence_b: Array[Vector2i] = []
	var previous_direction := TerritorySim.UNDEFINED_DIRECTION

	for _i in range(20):
		_assert_eq(sim_a.step_colony(1), true, "deterministic sim A step")
		_assert_eq(sim_b.step_colony(1), true, "deterministic sim B step")
		var state_a: Dictionary = sim_a.get_colony_debug_state(1)
		var state_b: Dictionary = sim_b.get_colony_debug_state(1)
		var direction: int = state_a["last_placement_direction"]
		if previous_direction != TerritorySim.UNDEFINED_DIRECTION:
			_assert_eq(direction != previous_direction, true, "no repeated direction")
		previous_direction = direction
		sequence_a.append(state_a["last_placed_cell"])
		sequence_b.append(state_b["last_placed_cell"])

	_assert_eq(sequence_a, sequence_b, "identical sims produce identical sequence")


func _test_reanchor_sequence_is_deterministic() -> void:
	var sim_a := _new_sim(3)
	var sim_b := _new_sim(3)
	var blocked_cells := _blocked_origin_cells()
	_apply_owned_cells(sim_a, blocked_cells, Vector2i.ZERO, 0)
	_apply_owned_cells(sim_b, blocked_cells, Vector2i.ZERO, 0)
	var sequence_a: Array[Vector2i] = []
	var sequence_b: Array[Vector2i] = []

	for _i in range(8):
		_assert_eq(sim_a.step_colony(1), true, "reanchor deterministic sim A step")
		_assert_eq(sim_b.step_colony(1), true, "reanchor deterministic sim B step")
		sequence_a.append(sim_a.get_colony_debug_state(1)["last_placed_cell"])
		sequence_b.append(sim_b.get_colony_debug_state(1)["last_placed_cell"])

	_assert_eq(sim_a.get_debug_metrics()["reanchors_total"] >= 1, true, "deterministic test used reanchor")
	_assert_eq(sequence_a, sequence_b, "reanchor sequence is deterministic")


func _test_one_cell_enclosure_fills() -> void:
	var sim := _new_sim(8)
	var center := Vector2i(3, 0)
	var ring := _ring_cells(center)
	var closing_cell: Vector2i = ring[0]
	var owned := [Vector2i.ZERO]
	owned.append_array(_without_cell(ring, closing_cell))
	_apply_owned_cells(sim, owned, owned[0], TerritorySim.UNDEFINED_DIRECTION)
	var placements_before: int = sim.get_colony_debug_state(1)["placements_total"]

	sim._place_cell(sim.colonies[1], closing_cell, 0)

	var state: Dictionary = sim.get_colony_debug_state(1)
	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(sim.get_owner_at(center), 1, "one-cell hole filled")
	_assert_eq(metrics["enclosure_regions_checked_last_step"] >= 1, true, "one-cell enclosure checked")
	_assert_eq(metrics["enclosure_filled_cells_last_step"], 1, "one-cell enclosure fill count")
	_assert_eq(metrics["changed_cells_last_step"], 2, "changed cells includes placement and fill")
	_assert_eq(state["placements_total"], placements_before + 1, "fill does not count as placement")
	_assert_eq(state["last_placed_cell"], closing_cell, "fill does not change last placed")
	_assert_eq(state["last_placement_direction"], 0, "fill does not change direction")


func _test_multi_cell_enclosure_fills() -> void:
	var sim := _new_sim(8)
	var region := [
		Vector2i(3, 0),
		Vector2i(4, 0),
	]
	var setup := _closed_region_setup(region)
	_apply_owned_cells(sim, setup["owned"], setup["owned"][0], TerritorySim.UNDEFINED_DIRECTION)

	sim._place_cell(sim.colonies[1], setup["closing_cell"], 0)

	var metrics: Dictionary = sim.get_debug_metrics()
	for cell in region:
		_assert_eq(sim.get_owner_at(cell), 1, "multi-cell enclosed cell filled")
	_assert_eq(metrics["enclosure_filled_cells_last_step"], 2, "multi-cell fill count")
	_assert_eq(metrics["changed_cells_last_step"], 3, "multi-cell changed count")


func _test_open_region_does_not_fill() -> void:
	var sim := _new_sim(2)
	var placed_cell := Vector2i.ZERO
	var owned := [
		HexGridMath.direction(1),
		HexGridMath.direction(3),
	]
	_apply_owned_cells(sim, owned, owned[0], TerritorySim.UNDEFINED_DIRECTION)

	sim._place_cell(sim.colonies[1], placed_cell, 0)

	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(metrics["enclosure_regions_checked_last_step"] > 0, true, "open region checked")
	_assert_eq(metrics["enclosure_filled_cells_last_step"], 0, "open region not filled")
	_assert_eq(sim.get_owner_at(HexGridMath.direction(0)), 0, "open neighbor remains empty")


func _test_contested_region_does_not_fill() -> void:
	var sim := _new_sim(8)
	var center := Vector2i(3, 0)
	var ring := _ring_cells(center)
	var closing_cell: Vector2i = ring[0]
	var contested_cell: Vector2i = ring[3]
	var owned := [Vector2i.ZERO]
	for cell in ring:
		if cell != closing_cell and cell != contested_cell:
			owned.append(cell)
	_apply_owned_cells(sim, owned, owned[0], TerritorySim.UNDEFINED_DIRECTION)
	sim.cell_owners[contested_cell] = 2

	sim._place_cell(sim.colonies[1], closing_cell, 0)

	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(sim.get_owner_at(center), 0, "contested region remains empty")
	_assert_eq(metrics["enclosure_regions_checked_last_step"] >= 1, true, "contested region checked")
	_assert_eq(metrics["enclosure_filled_cells_last_step"], 0, "contested region no fill")


func _test_normal_growth_skips_enclosure_scan() -> void:
	var sim := _new_sim(80)
	_assert_eq(sim.step_colony(1), true, "normal enclosure skip step")
	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(metrics["enclosure_regions_checked_last_step"], 0, "normal line skips enclosure scan")
	_assert_eq(metrics["enclosure_visited_cells_last_step"], 0, "normal line visits no enclosure cells")
	_assert_eq(metrics["enclosure_filled_cells_last_step"], 0, "normal line fills nothing")


func _test_enclosure_scan_cap_aborts() -> void:
	var sim := _new_sim(8)
	sim.enclosure_scan_cell_limit = 0
	var center := Vector2i(3, 0)
	var ring := _ring_cells(center)
	var closing_cell: Vector2i = ring[0]
	var owned := [Vector2i.ZERO]
	owned.append_array(_without_cell(ring, closing_cell))
	_apply_owned_cells(sim, owned, owned[0], TerritorySim.UNDEFINED_DIRECTION)

	sim._place_cell(sim.colonies[1], closing_cell, 0)

	var metrics: Dictionary = sim.get_debug_metrics()
	_assert_eq(sim.get_owner_at(center), 0, "scan cap leaves region empty")
	_assert_eq(metrics["enclosure_aborted_regions_last_step"] >= 1, true, "scan cap abort metric")
	_assert_eq(metrics["enclosure_filled_cells_last_step"], 0, "scan cap no fill")


func _test_sim_does_not_use_global_radius_scan() -> void:
	var content := FileAccess.get_file_as_string("res://src/sim/territory_sim.gd")
	_assert_eq(
		content.contains("coords_in_radius"),
		false,
		"sim enclosure logic must not use global radius scan"
	)


func _new_sim(radius: int) -> TerritorySim:
	var sim := TerritorySim.new()
	sim.configure(radius)
	_assert_eq(sim.spawn_colony(1, Vector2i.ZERO), true, "spawn colony")
	return sim


func _blocked_origin_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	for direction_index in range(6):
		cells.append(HexGridMath.direction(direction_index))
	return cells


func _ring_cells(center: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for direction_index in range(6):
		cells.append(center + HexGridMath.direction(direction_index))
	return cells


func _without_cell(cells: Array[Vector2i], excluded: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in cells:
		if cell != excluded:
			result.append(cell)
	return result


func _closed_region_setup(region: Array) -> Dictionary:
	var boundary: Array[Vector2i] = []
	var region_set := {}
	for cell in region:
		region_set[cell] = true

	for cell in region:
		for direction_index in range(6):
			var neighbor: Vector2i = cell + HexGridMath.direction(direction_index)
			if region_set.has(neighbor) or boundary.has(neighbor):
				continue
			boundary.append(neighbor)

	for candidate in boundary:
		var owned := [Vector2i.ZERO]
		for boundary_cell in boundary:
			if boundary_cell != candidate:
				owned.append(boundary_cell)
		if _owned_neighbor_count(candidate, owned) >= 2:
			return {
				"closing_cell": candidate,
				"owned": owned,
			}

	return {
		"closing_cell": boundary[0],
		"owned": [Vector2i.ZERO],
	}


func _owned_neighbor_count(coord: Vector2i, owned_cells: Array) -> int:
	var owned := {}
	for cell in owned_cells:
		owned[cell] = true

	var count := 0
	for direction_index in range(6):
		if owned.has(coord + HexGridMath.direction(direction_index)):
			count += 1

	return count


func _apply_owned_cells(
	sim: TerritorySim,
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


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s, got %s" % [label, expected, actual])
