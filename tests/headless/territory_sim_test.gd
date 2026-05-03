extends SceneTree

const TerritorySim = preload("res://src/sim/territory_sim.gd")
const HexGridMath = preload("res://src/core/hex/hex_grid_math.gd")

var _failures: Array[String] = []


func _init() -> void:
	_test_spawn_and_first_step()
	_test_turn_rule_rejects_straight_continuation()
	_test_occupied_and_out_of_bounds_rejections()
	_test_stall_when_no_valid_neighbor()
	_test_reset_restores_starter_state()
	_test_deterministic_sequence()

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


func _new_sim(radius: int) -> TerritorySim:
	var sim := TerritorySim.new()
	sim.configure(radius)
	_assert_eq(sim.spawn_colony(1, Vector2i.ZERO), true, "spawn colony")
	return sim


func _assert_eq(actual, expected, label: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s, got %s" % [label, expected, actual])
