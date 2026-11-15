extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2


func test_king_moves_one_tile_in_eight_directions() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var king := MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_1, Vector2i(8, 8))
	var destinations := _destinations(state, king)
	assert_eq(destinations.size(), 8, "open center king has eight destinations")
	for tile: Vector2i in [
		Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 7),
		Vector2i(7, 8), Vector2i(9, 8),
		Vector2i(7, 9), Vector2i(8, 9), Vector2i(9, 9),
	]:
		assert_true(tile in destinations, "king can reach %s" % str(tile))
	return true


func test_king_friendly_blocks_and_enemy_is_capturable() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var king := MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(7, 7))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(9, 9))
	var destinations := _destinations(state, king)
	assert_eq(destinations.size(), 7, "friendly destination is removed")
	assert_false(Vector2i(7, 7) in destinations, "friendly tile is blocked")
	assert_true(Vector2i(9, 9) in destinations, "enemy tile is capturable")
	return true


func test_king_is_not_filtered_by_check() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var king := MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_2, Vector2i(8, 0))
	var destinations := _destinations(state, king)
	assert_true(Vector2i(8, 7) in destinations, "king may remain on the attacked file")
	assert_true(Vector2i(9, 8) in destinations, "king may move while attacked")
	return true


func test_rook_rays_and_blocking() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(8, 8))
	var destinations := _destinations(state, rook)
	assert_eq(destinations.size(), 30, "open center rook ray length")
	assert_true(Vector2i(8, 0) in destinations, "rook reaches the far edge")
	assert_true(Vector2i(0, 8) in destinations, "rook reaches the left edge")
	assert_true(Vector2i(15, 8) in destinations, "rook reaches the right edge")

	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 6))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(11, 8))
	destinations = _destinations(state, rook)
	assert_true(Vector2i(8, 7) in destinations, "rook stops before a friendly piece")
	assert_false(Vector2i(8, 6) in destinations, "friendly piece is not capturable")
	assert_false(Vector2i(8, 5) in destinations, "ray does not pass through a friendly piece")
	assert_true(Vector2i(11, 8) in destinations, "first enemy is capturable")
	assert_false(Vector2i(12, 8) in destinations, "ray stops after the first enemy")
	return true


func test_rook_respects_irregular_boundary() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(4, 15))
	var destinations := _destinations(state, rook)
	assert_eq(destinations.size(), 22, "corner rook destination count")
	assert_true(Vector2i(4, 0) in destinations, "rook follows the playable column")
	assert_true(Vector2i(11, 15) in destinations, "rook reaches the last playable tile of the end row")
	assert_false(Vector2i(3, 15) in destinations, "void blocks the ray")
	assert_false(Vector2i(12, 15) in destinations, "void blocks the ray beyond the end row")
	return true


func test_bishop_diagonals_and_blocking() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var bishop := MovementTestUtils.add_unit(state, UnitType.Type.BISHOP, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(6, 6))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(10, 10))
	var destinations := _destinations(state, bishop)
	assert_true(Vector2i(7, 7) in destinations, "bishop reaches the tile before a friendly blocker")
	assert_false(Vector2i(6, 6) in destinations, "friendly blocker is not a destination")
	assert_false(Vector2i(5, 5) in destinations, "bishop does not pass through a friendly blocker")
	assert_true(Vector2i(10, 10) in destinations, "first enemy on a diagonal is capturable")
	assert_false(Vector2i(11, 11) in destinations, "diagonal stops after the capture")
	assert_true(Vector2i(9, 7) in destinations, "other diagonal remains available")
	assert_true(Vector2i(7, 9) in destinations, "both diagonal directions are generated")
	return true


func test_queen_combines_rays() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var queen := MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_1, Vector2i(8, 8))
	var destinations := _destinations(state, queen)
	assert_eq(destinations.size(), 51, "open center queen destination count")
	assert_true(Vector2i(8, 0) in destinations, "queen moves orthogonally")
	assert_true(Vector2i(7, 7) in destinations, "queen moves diagonally")
	assert_true(Vector2i(9, 7) in destinations, "queen covers all four diagonal quadrants")
	return true


func test_knight_jumps_and_captures() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var knight := MovementTestUtils.add_unit(state, UnitType.Type.KNIGHT, PLAYER_1, Vector2i(8, 8))
	var destinations := _destinations(state, knight)
	assert_eq(destinations.size(), 8, "open center knight has eight destinations")

	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 7))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(7, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(9, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 9))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(7, 6))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(9, 6))
	destinations = _destinations(state, knight)
	assert_eq(destinations.size(), 7, "friendly knight destination is removed")
	assert_false(Vector2i(7, 6) in destinations, "knight cannot land on a friendly unit")
	assert_true(Vector2i(9, 6) in destinations, "knight captures an enemy on its destination")
	assert_true(Vector2i(7, 10) in destinations, "adjacent blockers do not stop a jump")
	return true


func test_pawn_forward_moves() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 8))
	var destinations := _destinations(state, pawn)
	assert_eq(destinations.size(), 2, "pawn has two forward destinations")
	assert_true(Vector2i(8, 7) in destinations, "pawn moves one forward")
	assert_true(Vector2i(8, 6) in destinations, "pawn moves two forward on any move")
	assert_false(Vector2i(8, 9) in destinations, "pawn cannot move backward")
	assert_false(Vector2i(7, 7) in destinations, "empty diagonal is not a move")
	return true


func test_player_2_pawn_moves_down() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 8))
	var destinations := _destinations(state, pawn)
	assert_true(Vector2i(8, 9) in destinations, "player 2 pawn moves one down")
	assert_true(Vector2i(8, 10) in destinations, "player 2 pawn moves two down")
	assert_false(Vector2i(8, 7) in destinations, "player 2 pawn cannot move up")
	return true


func test_pawn_two_step_blocked_by_occupied_intermediate() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 7))
	var destinations := _destinations(state, pawn)
	assert_false(Vector2i(8, 6) in destinations, "occupied intermediate blocks the two-step move")
	assert_false(Vector2i(8, 7) in destinations, "friendly intermediate is not a destination")

	var enemy_state := MovementTestUtils.empty_state()
	assert_not_null(enemy_state, "enemy state built")
	if enemy_state == null:
		return true
	var enemy_pawn := MovementTestUtils.add_unit(enemy_state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(enemy_state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 7))
	var enemy_destinations := _destinations(enemy_state, enemy_pawn)
	assert_false(Vector2i(8, 6) in enemy_destinations, "forward two-step is blocked by any piece")
	assert_false(Vector2i(8, 7) in enemy_destinations, "pawn cannot capture straight ahead")
	return true


func test_pawn_diagonal_capture() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(7, 7))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(9, 7))
	var destinations := _destinations(state, pawn)
	assert_true(Vector2i(7, 7) in destinations, "enemy diagonal is capturable")
	assert_false(Vector2i(9, 7) in destinations, "friendly diagonal is blocked")
	assert_true(Vector2i(8, 7) in destinations, "forward move remains available")
	assert_eq(destinations.size(), 3, "pawn destination count with one capture")
	return true


func test_pawn_promotion() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 1))
	var result := MovementRules.move_unit(
		state, pawn, Vector2i(8, 0), ExplorationProvider.all_explored(), UnitType.Type.QUEEN
	)
	assert_true(result.success, "promotion move succeeds")
	assert_eq(pawn.type, UnitType.Type.QUEEN, "pawn promotes to queen")
	assert_eq(result.promoted_to, UnitType.Type.QUEEN, "result records the promotion")
	assert_eq(state.get_unit_at(Vector2i(8, 0)).id, pawn.id, "promoted unit occupies the end row")

	var knight_pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 14))
	var knight_result := MovementRules.move_unit(
		state, knight_pawn, Vector2i(8, 15), ExplorationProvider.all_explored(), UnitType.Type.KNIGHT
	)
	assert_true(knight_result.success, "player 2 promotion move succeeds")
	assert_eq(knight_pawn.type, UnitType.Type.KNIGHT, "player 2 pawn promotes to knight")
	return true


func test_invalid_promotion_is_rejected() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 1))
	var result := MovementRules.move_unit(
		state, pawn, Vector2i(8, 0), ExplorationProvider.all_explored(), UnitType.Type.PAWN
	)
	assert_false(result.success, "pawn promotion choice is rejected")
	assert_eq(result.error, "Invalid promotion choice", "invalid promotion reports an error")
	assert_eq(pawn.type, UnitType.Type.PAWN, "failed promotion leaves the pawn unchanged")
	assert_eq(pawn.tile, Vector2i(8, 1), "failed promotion leaves the pawn in place")
	return true


func test_rook_capture_removes_enemy() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(8, 8))
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 5))
	var result := MovementRules.move_unit(
		state, rook, Vector2i(8, 5), ExplorationProvider.all_explored()
	)
	assert_true(result.success, "capture move succeeds")
	assert_not_null(result.captured_unit, "result records the captured unit")
	if result.captured_unit != null:
		assert_eq(result.captured_unit.id, enemy.id, "captured unit id")
		assert_eq(result.captured_unit.type, UnitType.Type.PAWN, "captured unit type")
	assert_null(state.get_unit(enemy.id), "captured unit is removed from the state")
	assert_eq(state.get_unit_at(Vector2i(8, 5)).id, rook.id, "rook occupies the captured tile")
	assert_eq(state.units.size(), 1, "only the rook remains")
	return true


func test_friendly_capture_is_rejected() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(8, 8))
	var friendly := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 5))
	var destinations := _destinations(state, rook)
	assert_false(Vector2i(8, 5) in destinations, "friendly tile is not a destination")
	var result := MovementRules.move_unit(
		state, rook, Vector2i(8, 5), ExplorationProvider.all_explored()
	)
	assert_false(result.success, "friendly capture is rejected")
	assert_eq(rook.tile, Vector2i(8, 8), "rook stays in place")
	assert_eq(state.get_unit_at(Vector2i(8, 5)).id, friendly.id, "friendly unit is unharmed")
	return true


func test_illegal_destination_is_rejected() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(8, 8))
	var result := MovementRules.move_unit(
		state, rook, Vector2i(9, 9), ExplorationProvider.all_explored()
	)
	assert_false(result.success, "diagonal rook move is rejected")
	assert_true(result.error.contains("Illegal destination"), "rejection reports the reason")
	assert_eq(rook.tile, Vector2i(8, 8), "rook stays in place")
	assert_true(state.occupancy.has(Vector2i(8, 8)), "occupancy is unchanged")
	return true


func _destinations(state: GameState, unit: GameUnit) -> Array[Vector2i]:
	return MovementRules.legal_destinations(state, unit, ExplorationProvider.all_explored())
