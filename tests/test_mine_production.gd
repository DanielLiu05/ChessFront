extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const MINE_A: Vector2i = Vector2i(5, 6)
const MINE_B: Vector2i = Vector2i(10, 9)


func test_occupied_mine_pays_after_four_actions() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var mine := state.get_gold_mine_at(MINE_A)
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, MINE_A)
	var report := EconomyReport.new()
	for step in range(1, 4):
		EconomySystem.advance_mines(state, report)
		assert_eq(mine.cycle_progress, step, "cycle advances to %d" % step)
		assert_eq(state.get_gold(PLAYER_1), 0, "no payout before four actions")
		assert_false(mine.gold_available, "no token while occupied")
	EconomySystem.advance_mines(state, report)
	assert_eq(mine.cycle_progress, 0, "cycle resets after payout")
	assert_eq(state.get_gold(PLAYER_1), 1, "occupant owner receives one gold")
	assert_false(mine.gold_available, "occupied mine does not create a token")
	assert_eq(int(report.gold_gained.get(PLAYER_1, 0)), 1, "report records the payout")
	return true


func test_unoccupied_mine_creates_one_token_and_pauses() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var mine := state.get_gold_mine_at(MINE_A)
	var report := EconomyReport.new()
	_advance(state, 4, report)
	assert_true(mine.gold_available, "unoccupied mine creates a token")
	assert_eq(mine.cycle_progress, 0, "cycle pauses at the token")
	assert_eq(state.get_gold(PLAYER_1), 0, "no gold without an occupant")
	assert_true(report.tokens_spawned.has(MINE_A), "token spawn is reported")

	var paused_report := EconomyReport.new()
	_advance(state, 5, paused_report)
	assert_true(mine.gold_available, "token remains available")
	assert_eq(mine.cycle_progress, 0, "paused mine never advances")
	assert_false(paused_report.gold_gained.has(PLAYER_1), "paused mine pays nothing")
	assert_true(paused_report.tokens_spawned.is_empty(), "paused mine spawns nothing new")
	return true


func test_token_collection_resets_the_cycle() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var mine := state.get_gold_mine_at(MINE_A)
	_advance(state, 4, EconomyReport.new())
	var unit := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_2, MINE_A)
	var report := EconomyReport.new()
	EconomySystem.collect_token(state, unit, report)
	assert_false(mine.gold_available, "token is collected")
	assert_eq(mine.cycle_progress, 0, "cycle resets on collection")
	assert_eq(state.get_gold(PLAYER_2), 1, "collector owner receives one gold")
	assert_eq(int(report.gold_gained.get(PLAYER_2, 0)), 1, "collection is reported")
	assert_true(report.tokens_collected.has(MINE_A), "collected tile is reported")

	EconomySystem.collect_token(state, unit, report)
	assert_eq(state.get_gold(PLAYER_2), 1, "token cannot be collected twice")
	EconomySystem.advance_mines(state, EconomyReport.new())
	assert_eq(mine.cycle_progress, 1, "a new cycle starts after collection")
	return true


func test_owner_change_changes_the_recipient() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var p1_unit := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, MINE_A)
	_advance(state, 3, EconomyReport.new())
	MovementTestUtils.relocate_unit(state, p1_unit, Vector2i(4, 6))
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_2, MINE_A)
	EconomySystem.advance_mines(state, EconomyReport.new())
	assert_eq(state.get_gold(PLAYER_1), 0, "old occupant is not paid")
	assert_eq(state.get_gold(PLAYER_2), 1, "current occupant is paid")
	return true


func test_mines_are_independent() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var mine_a := state.get_gold_mine_at(MINE_A)
	var mine_b := state.get_gold_mine_at(MINE_B)
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, MINE_A)
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_2, MINE_B)
	var report := EconomyReport.new()
	_advance(state, 4, report)
	assert_eq(state.get_gold(PLAYER_1), 1, "player 1 mine pays")
	assert_eq(state.get_gold(PLAYER_2), 1, "player 2 mine pays")
	assert_eq(mine_a.cycle_progress, 0, "first mine resets")
	assert_eq(mine_b.cycle_progress, 0, "second mine resets")
	assert_false(mine_a.gold_available, "first mine has no token")
	assert_false(mine_b.gold_available, "second mine has no token")
	assert_eq(int(report.gold_gained.get(PLAYER_1, 0)), 1, "first payout is reported")
	assert_eq(int(report.gold_gained.get(PLAYER_2, 0)), 1, "second payout is reported")
	return true


func test_collection_without_token_does_nothing() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var unit := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, MINE_A)
	var report := EconomyReport.new()
	EconomySystem.collect_token(state, unit, report)
	assert_eq(state.get_gold(PLAYER_1), 0, "no gold without a token")
	assert_true(report.tokens_collected.is_empty(), "no collection is reported")
	return true


func _terrain_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load mine test map: %s" % str(result.errors))
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.reset_knowledge(state)
	return state


func _advance(state: GameState, times: int, report: EconomyReport) -> void:
	for _step in range(times):
		EconomySystem.advance_mines(state, report)
