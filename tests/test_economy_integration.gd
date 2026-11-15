extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const MINE_A: Vector2i = Vector2i(5, 6)
const MINE_B: Vector2i = Vector2i(10, 9)


func test_move_advances_mine_cycle_once() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.reset_knowledge(state)
	var result := _resolve(state, MoveAction.new(rook.id, Vector2i(8, 7)))
	assert_true(result.success, "move succeeds")
	for mine: GoldMine in state.gold_mines:
		assert_eq(mine.cycle_progress, 1, "one action advances each mine once")
		assert_false(mine.gold_available, "no token after one action")
	assert_eq(state.get_gold(PLAYER_1), 0, "no gold yet")
	assert_eq(state.active_player, PLAYER_2, "turn advances")
	return true


func test_pass_creates_tokens_then_collection_starts_new_cycle() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var fourth := ActionResult.new()
	for step in range(1, 5):
		var result := _resolve(state, PassAction.new())
		assert_true(result.success, "pass %d succeeds" % step)
		if step < 4:
			assert_eq(state.get_gold_mine_at(MINE_A).cycle_progress, step, "cycle advances on pass")
		else:
			fourth = result
	var mine_a := state.get_gold_mine_at(MINE_A)
	var mine_b := state.get_gold_mine_at(MINE_B)
	assert_true(mine_a.gold_available, "mine A token appears")
	assert_true(mine_b.gold_available, "mine B token appears")
	assert_eq(mine_a.cycle_progress, 0, "mine A pauses")
	assert_eq(mine_b.cycle_progress, 0, "mine B pauses")
	assert_eq(state.get_gold(PLAYER_1), 0, "tokens are not gold yet")
	assert_eq(fourth.tokens_spawned.size(), 2, "fourth action reports both tokens")

	for _step in range(2):
		assert_true(_resolve(state, PassAction.new()).success, "pass with paused tokens succeeds")
	assert_true(mine_a.gold_available, "token does not expire")
	assert_eq(mine_a.cycle_progress, 0, "paused mine still does not advance")
	assert_eq(state.get_gold(PLAYER_1), 0, "uncollected tokens do not pay")

	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(4, 6))
	MovementTestUtils.reset_knowledge(state)
	var collect := _resolve(state, MoveAction.new(rook.id, MINE_A))
	assert_true(collect.success, "rook enters the token mine")
	assert_eq(state.get_gold(PLAYER_1), 1, "collector receives one gold")
	assert_false(mine_a.gold_available, "token is cleared")
	assert_eq(mine_a.cycle_progress, 1, "collection action starts the next cycle")
	assert_eq(int(collect.gold_gained.get(PLAYER_1, 0)), 1, "result reports collected gold")
	assert_true(collect.tokens_collected.has(MINE_A), "result reports the collected tile")
	return true


func test_occupied_mine_pays_on_fourth_action() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, MINE_A)
	var p1_knight := MovementTestUtils.add_unit(
		state, UnitType.Type.KNIGHT, PLAYER_1, Vector2i(8, 8)
	)
	var p2_knight := MovementTestUtils.add_unit(
		state, UnitType.Type.KNIGHT, PLAYER_2, Vector2i(8, 4)
	)
	MovementTestUtils.reset_knowledge(state)

	assert_true(_resolve(state, MoveAction.new(p1_knight.id, Vector2i(7, 6))).success, "move 1")
	assert_true(_resolve(state, MoveAction.new(p2_knight.id, Vector2i(7, 2))).success, "move 2")
	assert_true(_resolve(state, MoveAction.new(p1_knight.id, Vector2i(8, 8))).success, "move 3")
	var fourth := _resolve(state, MoveAction.new(p2_knight.id, Vector2i(8, 4)))
	assert_true(fourth.success, "move 4")

	var mine_a := state.get_gold_mine_at(MINE_A)
	var mine_b := state.get_gold_mine_at(MINE_B)
	assert_eq(state.get_gold(PLAYER_1), 1, "occupant owner is paid")
	assert_eq(state.get_gold(PLAYER_2), 0, "action owner is not paid")
	assert_eq(mine_a.cycle_progress, 0, "paid mine resets")
	assert_true(mine_b.gold_available, "unoccupied mine creates a token")
	assert_eq(int(fourth.gold_gained.get(PLAYER_1, 0)), 1, "payout is reported")
	assert_true(fourth.tokens_spawned.has(MINE_B), "token spawn is reported")
	return true


func test_non_move_actions_advance_mines() -> bool:
	var pass_state := _terrain_state()
	assert_not_null(pass_state, "pass state built")
	if pass_state == null:
		return true
	assert_true(_resolve(pass_state, PassAction.new()).success, "pass succeeds")
	assert_eq(
		pass_state.get_gold_mine_at(MINE_A).cycle_progress,
		1,
		"pass advances mine cycles"
	)

	var recruit_state := _terrain_state()
	assert_not_null(recruit_state, "recruit state built")
	if recruit_state == null:
		return true
	recruit_state.add_gold(PLAYER_1, 1)
	assert_true(
		_resolve(recruit_state, RecruitAction.new(UnitType.Type.PAWN, Vector2i(3, 14))).success,
		"recruitment succeeds"
	)
	assert_eq(
		recruit_state.get_gold_mine_at(MINE_A).cycle_progress,
		1,
		"recruitment advances mine cycles"
	)

	var bridge_state := _terrain_state()
	assert_not_null(bridge_state, "bridge state built")
	if bridge_state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		bridge_state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(4, 6)
	)
	MovementTestUtils.reset_knowledge(bridge_state)
	assert_true(
		_resolve(bridge_state, BuildBridgeAction.new(engineer.id, Vector2i(5, 7))).success,
		"bridge construction succeeds"
	)
	assert_eq(
		bridge_state.get_gold_mine_at(MINE_A).cycle_progress,
		1,
		"bridge action advances mine cycles"
	)
	return true


func test_king_capture_skips_economy() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var queen := MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 6))
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, MINE_A)
	for mine: GoldMine in state.gold_mines:
		mine.cycle_progress = 3
		mine.gold_available = false
	MovementTestUtils.reset_knowledge(state)

	var result := _resolve(state, MoveAction.new(queen.id, Vector2i(8, 6)))
	assert_true(result.success, "king capture succeeds")
	assert_true(result.game_over, "game ends immediately")
	assert_eq(state.get_gold(PLAYER_1), 0, "no mine payout occurs")
	for mine: GoldMine in state.gold_mines:
		assert_eq(mine.cycle_progress, 3, "mine counters do not advance")
		assert_false(mine.gold_available, "no token is created")
	assert_true(result.gold_gained.is_empty(), "no economy gold is reported")
	assert_true(result.tokens_spawned.is_empty(), "no tokens are reported")
	return true


func _terrain_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load economy integration map: %s" % str(result.errors))
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.reset_knowledge(state)
	return state


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
