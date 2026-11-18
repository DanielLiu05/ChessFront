extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const MAP_PATH: String = "res://maps/standard_template.json"
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const MINE_A: Vector2i = Vector2i(5, 6)


func test_turn_limit_is_configurable() -> bool:
	var result := MapIO.load_from_file(MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var default_state := GameState.new(result.map)
	assert_eq(
		default_state.turn_limit_plies,
		GameConfig.DEFAULT_TURN_LIMIT_PLIES,
		"default turn limit comes from config"
	)
	assert_eq(GameConfig.DEFAULT_TURN_LIMIT_PLIES, 200, "default turn limit is 200 plies")
	var short_state := GameState.new(result.map, 4)
	assert_eq(short_state.turn_limit_plies, 4, "constructor overrides the turn limit")
	var snapshot := short_state.snapshot()
	assert_eq(int(snapshot["turn_limit_plies"]), 4, "snapshot records the turn limit")
	return true


func test_turn_limit_draw_after_configured_plies() -> bool:
	var state := _standard_state(4)
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.clear_units(state)
	MovementTestUtils.clear_gold(state)
	MovementTestUtils.reset_knowledge(state)
	var final := ActionResult.new()
	for step in range(1, 5):
		var result := _resolve(state, PassAction.new())
		assert_true(result.success, "pass %d succeeds" % step)
		if step < 4:
			assert_false(result.draw, "no draw before the limit")
		else:
			final = result
	assert_true(final.draw, "turn-limit draw is reported")
	assert_eq(final.draw_reason, DrawSystem.REASON_TURN_LIMIT, "turn-limit reason")
	assert_true(state.game_over, "turn-limit draw ends the game")
	assert_eq(state.winner, GameConfig.NO_PLAYER, "draw has no winner")
	assert_eq(state.draw_reason, DrawSystem.REASON_TURN_LIMIT, "state records the draw reason")
	assert_eq(state.ply, 4, "limit is checked after the fourth ply")
	var snapshot := state.snapshot()
	assert_eq(snapshot["draw_reason"], DrawSystem.REASON_TURN_LIMIT, "snapshot records the draw")
	assert_true(snapshot["game_over"], "snapshot records game over")
	var blocked := _resolve(state, PassAction.new())
	assert_false(blocked.success, "no actions after a draw")
	return true


func test_threefold_repetition_draws() -> bool:
	var state := _standard_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var p1_knight := state.get_unit_at(Vector2i(5, 15))
	var p2_knight := state.get_unit_at(Vector2i(10, 0))
	assert_not_null(p1_knight, "player 1 knight")
	assert_not_null(p2_knight, "player 2 knight")
	if p1_knight == null or p2_knight == null:
		return true

	var final := ActionResult.new()
	for cycle in range(2):
		var moves: Array[MoveAction] = [
			MoveAction.new(p1_knight.id, Vector2i(6, 13)),
			MoveAction.new(p2_knight.id, Vector2i(9, 2)),
			MoveAction.new(p1_knight.id, Vector2i(5, 15)),
			MoveAction.new(p2_knight.id, Vector2i(10, 0)),
		]
		for action: MoveAction in moves:
			var result := _resolve(state, action)
			assert_true(result.success, "knight shuffle move succeeds")
			if cycle == 0:
				assert_false(result.draw, "no draw before the third occurrence")
			final = result

	assert_true(final.draw, "third occurrence draws")
	assert_eq(final.draw_reason, DrawSystem.REASON_THREEFOLD, "threefold reason")
	assert_true(state.game_over, "threefold draw ends the game")
	assert_eq(state.winner, GameConfig.NO_PLAYER, "threefold draw has no winner")
	assert_eq(state.active_player, PLAYER_1, "position includes the player to move")
	assert_eq(state.ply, 8, "draw occurs on the eighth ply")
	return true


func test_draw_agreement_outside_turn_system() -> bool:
	var state := _standard_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	assert_true(DrawSystem.offer_draw(state, PLAYER_1), "player 1 offers a draw")
	assert_eq(state.draw_offered_by, int(PLAYER_1), "offer is pending")
	assert_eq(state.active_player, PLAYER_1, "offer does not change the turn")
	assert_eq(state.ply, 0, "offer does not advance the ply counter")
	assert_false(DrawSystem.offer_draw(state, PLAYER_2), "cannot offer while one is pending")
	assert_false(DrawSystem.accept_draw(state, PLAYER_1), "offerer cannot accept their own offer")

	assert_true(DrawSystem.decline_draw(state, PLAYER_2), "opponent declines")
	assert_eq(state.draw_offered_by, GameConfig.NO_PLAYER, "decline clears the offer")
	assert_false(state.game_over, "decline does not end the game")
	assert_eq(state.active_player, PLAYER_1, "decline does not change the turn")

	assert_true(DrawSystem.offer_draw(state, PLAYER_2), "player 2 offers a draw")
	assert_true(DrawSystem.accept_draw(state, PLAYER_1), "player 1 accepts")
	assert_true(state.game_over, "agreement ends the game")
	assert_eq(state.winner, GameConfig.NO_PLAYER, "agreed draw has no winner")
	assert_eq(state.draw_reason, DrawSystem.REASON_AGREEMENT, "agreement reason")
	assert_eq(state.active_player, PLAYER_1, "agreement does not change the turn")
	assert_eq(state.ply, 0, "agreement does not advance the ply counter")
	assert_eq(state.draw_offered_by, GameConfig.NO_PLAYER, "agreement clears the offer")
	assert_eq(state.snapshot()["draw_reason"], DrawSystem.REASON_AGREEMENT, "snapshot records agreement")
	assert_false(DrawSystem.offer_draw(state, PLAYER_1), "cannot offer after the game ends")
	return true


func test_position_key_matches_rule_definition() -> bool:
	var base := _terrain_state()
	assert_not_null(base, "base state built")
	if base == null:
		return true
	var base_key := DrawSystem.position_key(base)

	var gold_state := _terrain_state()
	gold_state.add_gold(PLAYER_1, 1)
	assert_ne(base_key, DrawSystem.position_key(gold_state), "gold is part of the position")

	var mine_state := _terrain_state()
	mine_state.get_gold_mine_at(MINE_A).cycle_progress = 1
	assert_ne(base_key, DrawSystem.position_key(mine_state), "mine state is part of the position")

	var bridge_state := _terrain_state()
	bridge_state.board.get_tile(Vector2i(5, 7)).has_bridge = true
	assert_ne(base_key, DrawSystem.position_key(bridge_state), "bridges are part of the position")

	var active_state := _terrain_state()
	active_state.active_player = GameConfig.Player.PLAYER_2
	assert_ne(base_key, DrawSystem.position_key(active_state), "player to move is part of the position")

	var knowledge_state := _terrain_state()
	knowledge_state.get_knowledge(PLAYER_1).explored.clear()
	assert_eq(base_key, DrawSystem.position_key(knowledge_state), "knowledge is excluded from the position")
	return true


func test_king_capture_precedes_draw_checks() -> bool:
	var state := _standard_state(1)
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.clear_units(state)
	MovementTestUtils.reset_knowledge(state)
	var queen := MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 6))
	MovementTestUtils.reset_knowledge(state)
	var result := _resolve(state, MoveAction.new(queen.id, Vector2i(8, 6)))
	assert_true(result.success, "king capture succeeds")
	assert_false(result.draw, "king capture is not a draw")
	assert_true(result.game_over, "game ends immediately")
	assert_eq(result.winner, int(PLAYER_1), "capturing player wins")
	assert_eq(state.draw_reason, "", "no draw reason is recorded")
	assert_eq(state.ply, 0, "king capture skips turn advancement")
	return true


func _standard_state(turn_limit: int = GameConfig.DEFAULT_TURN_LIMIT_PLIES) -> GameState:
	var result := MapIO.load_from_file(MAP_PATH)
	if not result.is_valid():
		push_error("Could not load draw test map: %s" % str(result.errors))
		return null
	return GameState.new(result.map, turn_limit)


func _terrain_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load terrain draw map: %s" % str(result.errors))
		return null
	return GameState.new(result.map)


func _resolve(state: GameState, action: GameAction) -> ActionResult:
	return ActionResolver.resolve(state, action, ExplorationProvider.all_explored())
