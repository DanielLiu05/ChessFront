extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const MAP_PATH: String = "res://maps/standard_template.json"


func test_turns_alternate_and_ply_advances() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var p1_pawn := state.get_unit_at(Vector2i(4, 14))
	var p2_pawn := state.get_unit_at(Vector2i(4, 1))
	assert_not_null(p1_pawn, "player 1 pawn")
	assert_not_null(p2_pawn, "player 2 pawn")
	if p1_pawn == null or p2_pawn == null:
		return true

	var first := ActionResolver.resolve(
		state, MoveAction.new(p1_pawn.id, Vector2i(4, 13)), _exploration()
	)
	assert_true(first.success, "player 1 move succeeds")
	assert_eq(state.active_player, PLAYER_2, "player 2 becomes active")
	assert_eq(state.ply, 1, "ply advances once")

	var second := ActionResolver.resolve(
		state, MoveAction.new(p2_pawn.id, Vector2i(4, 2)), _exploration()
	)
	assert_true(second.success, "player 2 move succeeds")
	assert_eq(state.active_player, PLAYER_1, "player 1 becomes active again")
	assert_eq(state.ply, 2, "ply advances twice")
	return true


func test_enemy_unit_cannot_be_moved() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var enemy_pawn := state.get_unit_at(Vector2i(4, 1))
	assert_not_null(enemy_pawn, "enemy pawn")
	if enemy_pawn == null:
		return true
	var before := state.snapshot_text()
	var result := ActionResolver.resolve(
		state, MoveAction.new(enemy_pawn.id, Vector2i(4, 2)), _exploration()
	)
	assert_false(result.success, "enemy unit move is rejected")
	assert_true(result.error.contains("active player"), "ownership error is clear")
	assert_eq(state.snapshot_text(), before, "state is unchanged")
	return true


func test_invalid_destination_does_not_consume_turn() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := state.get_unit_at(Vector2i(4, 14))
	assert_not_null(pawn, "pawn")
	if pawn == null:
		return true
	var before := state.snapshot_text()
	var result := ActionResolver.resolve(
		state, MoveAction.new(pawn.id, Vector2i(3, 14)), _exploration()
	)
	assert_false(result.success, "sideways pawn move is rejected")
	assert_eq(state.snapshot_text(), before, "state is unchanged")
	assert_eq(pawn.tile, Vector2i(4, 14), "pawn stays in place")
	return true


func test_friendly_capture_does_not_consume_turn() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(8, 8))
	var friendly := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 5))
	MovementTestUtils.reset_knowledge(state)
	var before := state.snapshot_text()
	var result := ActionResolver.resolve(
		state, MoveAction.new(rook.id, Vector2i(8, 5)), _exploration()
	)
	assert_false(result.success, "friendly capture is rejected")
	assert_eq(state.snapshot_text(), before, "state is unchanged")
	assert_eq(state.get_unit_at(Vector2i(8, 5)).id, friendly.id, "friendly unit is unharmed")
	return true


func test_pass_is_only_available_without_legal_moves() -> bool:
	var deployed := _deployed_state()
	assert_not_null(deployed, "deployed state built")
	if deployed == null:
		return true
	var before := deployed.snapshot_text()
	var rejected := ActionResolver.resolve(deployed, PassAction.new(), _exploration())
	assert_false(rejected.success, "pass is rejected while moves exist")
	assert_eq(deployed.snapshot_text(), before, "rejected pass changes nothing")

	var empty := MovementTestUtils.empty_state()
	assert_not_null(empty, "empty state built")
	if empty == null:
		return true
	var accepted := ActionResolver.resolve(empty, PassAction.new(), _exploration())
	assert_true(accepted.success, "pass is accepted with no legal moves")
	assert_eq(empty.active_player, PLAYER_2, "pass advances the turn")
	assert_eq(empty.ply, 1, "pass advances the ply counter")
	return true


func test_king_capture_ends_game_without_turn_advance() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var queen := MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_1, Vector2i(8, 8))
	var king := MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 6))
	MovementTestUtils.reset_knowledge(state)
	var result := ActionResolver.resolve(
		state, MoveAction.new(queen.id, Vector2i(8, 6)), _exploration()
	)
	assert_true(result.success, "king capture succeeds")
	assert_not_null(result.captured_unit, "captured unit is reported")
	if result.captured_unit != null:
		assert_eq(result.captured_unit.type, UnitType.Type.KING, "captured unit is the king")
	assert_true(state.game_over, "game ends immediately")
	assert_eq(state.winner, PLAYER_1, "capturing player wins")
	assert_eq(state.active_player, PLAYER_1, "turn does not advance after king capture")
	assert_eq(state.ply, 0, "ply does not advance after king capture")
	assert_null(state.get_unit(king.id), "captured king is removed")
	return true


func test_actions_are_rejected_after_game_over() -> bool:
	var state := _run_scripted_match()
	assert_not_null(state, "match built")
	if state == null:
		return true
	assert_true(state.game_over, "match ended")
	var result := ActionResolver.resolve(state, PassAction.new(), _exploration())
	assert_false(result.success, "action after game over is rejected")
	assert_true(result.error.contains("Game is over"), "game-over error is clear")
	return true


func test_king_can_move_into_attack() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var king := MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_2, Vector2i(8, 0))
	MovementTestUtils.reset_knowledge(state)
	var result := ActionResolver.resolve(
		state, MoveAction.new(king.id, Vector2i(8, 7)), _exploration()
	)
	assert_true(result.success, "king may move into an attacked tile")
	assert_eq(king.tile, Vector2i(8, 7), "king moved")
	assert_eq(state.active_player, PLAYER_2, "turn advances")
	return true


func test_promotion_action() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 1))
	MovementTestUtils.reset_knowledge(state)
	var result := ActionResolver.resolve(
		state,
		MoveAction.new(pawn.id, Vector2i(8, 0), UnitType.Type.KNIGHT),
		_exploration()
	)
	assert_true(result.success, "promotion action succeeds")
	assert_eq(pawn.type, UnitType.Type.KNIGHT, "promotion choice is applied")
	assert_eq(state.active_player, PLAYER_2, "promotion consumes the turn")
	assert_eq(state.ply, 1, "promotion advances the ply counter")
	return true


func test_validate_does_not_mutate_state() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := state.get_unit_at(Vector2i(4, 14))
	assert_not_null(pawn, "pawn")
	if pawn == null:
		return true
	var action := MoveAction.new(pawn.id, Vector2i(4, 13))
	var before := state.snapshot_text()
	var validation := ActionResolver.validate(state, action, _exploration())
	assert_true(validation.success, "move validates")
	assert_eq(state.snapshot_text(), before, "validation does not mutate state")

	var result := ActionResolver.resolve(state, action, _exploration())
	assert_true(result.success, "validated move resolves")
	assert_ne(state.snapshot_text(), before, "resolved move updates state")
	return true


func test_scripted_match_is_deterministic() -> bool:
	var first := _run_scripted_match()
	var second := _run_scripted_match()
	assert_not_null(first, "first match built")
	assert_not_null(second, "second match built")
	if first == null or second == null:
		return true
	assert_true(first.game_over, "scripted match ends by king capture")
	assert_eq(first.winner, PLAYER_1, "player 1 wins the scripted match")
	assert_eq(first.ply, 2, "king capture does not advance the ply counter")
	assert_eq(first.active_player, PLAYER_1, "king capture does not advance the turn")
	assert_eq(first.snapshot_text(), second.snapshot_text(), "scripted match is deterministic")
	return true


func _deployed_state() -> GameState:
	var result := MapIO.load_from_file(MAP_PATH)
	if not result.is_valid():
		push_error("Could not load action test map: %s" % str(result.errors))
		return null
	return GameState.new(result.map)


func _run_scripted_match() -> GameState:
	var state := MovementTestUtils.empty_state()
	if state == null:
		return null
	var queen := MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_1, Vector2i(8, 8))
	var king := MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 5))
	MovementTestUtils.reset_knowledge(state)
	var exploration := _exploration()
	var first := ActionResolver.resolve(state, MoveAction.new(queen.id, Vector2i(8, 6)), exploration)
	var second := ActionResolver.resolve(state, MoveAction.new(king.id, Vector2i(7, 5)), exploration)
	var third := ActionResolver.resolve(state, MoveAction.new(queen.id, Vector2i(7, 5)), exploration)
	if not first.success or not second.success or not third.success:
		push_error("Scripted match action failed")
	return state


func _exploration() -> ExplorationProvider:
	return ExplorationProvider.all_explored()
