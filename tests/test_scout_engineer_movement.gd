extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2


func test_scout_has_five_tile_reach_when_all_explored() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	var destinations := _destinations(state, scout, ExplorationProvider.all_explored())
	assert_eq(destinations.size(), 40, "open scout explored-reach destination count")
	assert_true(Vector2i(8, 3) in destinations, "scout reaches five tiles north")
	assert_false(Vector2i(8, 2) in destinations, "scout cannot exceed explored reach")
	assert_true(Vector2i(3, 3) in destinations, "scout reaches five tiles diagonally")
	assert_true(Vector2i(13, 13) in destinations, "all four diagonal quadrants are generated")
	assert_false(Vector2i(9, 6) in destinations, "scout does not move off its straight lines")
	return true


func test_engineer_has_four_tile_reach_when_all_explored() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(8, 8))
	var destinations := _destinations(state, engineer, ExplorationProvider.all_explored())
	assert_eq(destinations.size(), 32, "open engineer explored-reach destination count")
	assert_true(Vector2i(8, 4) in destinations, "engineer reaches four tiles north")
	assert_false(Vector2i(8, 3) in destinations, "engineer cannot exceed explored reach")
	assert_true(Vector2i(4, 4) in destinations, "engineer reaches four tiles diagonally")
	return true


func test_scout_base_reach_without_exploration() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	var unexplored := ExplorationProvider.from_tiles([])
	var destinations := _destinations(state, scout, unexplored)
	assert_eq(destinations.size(), 24, "scout keeps three-tile base reach")
	assert_true(Vector2i(8, 5) in destinations, "base reach reaches three tiles")
	assert_false(Vector2i(8, 4) in destinations, "extended reach requires exploration")
	assert_true(Vector2i(5, 8) in destinations, "base reach applies in every direction")
	assert_false(Vector2i(4, 8) in destinations, "extended reach is refused in every direction")
	return true


func test_engineer_base_reach_without_exploration() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(8, 8))
	var unexplored := ExplorationProvider.from_tiles([])
	var destinations := _destinations(state, engineer, unexplored)
	assert_eq(destinations.size(), 16, "engineer keeps two-tile base reach")
	assert_true(Vector2i(8, 6) in destinations, "base reach reaches two tiles")
	assert_false(Vector2i(8, 5) in destinations, "extended reach requires exploration")
	return true


func test_scout_extended_reach_requires_path_exploration() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	var partially_explored := ExplorationProvider.from_tiles([
		Vector2i(8, 7),
		Vector2i(8, 6),
		Vector2i(8, 5),
		Vector2i(8, 4),
	])
	var destinations := _destinations(state, scout, partially_explored)
	assert_eq(destinations.size(), 25, "only the fully explored direction gains extended reach")
	assert_true(Vector2i(8, 4) in destinations, "fully explored path extends north reach")
	assert_false(Vector2i(8, 3) in destinations, "the next unexplored tile stops extended reach")
	assert_true(Vector2i(8, 11) in destinations, "base reach remains available elsewhere")
	assert_false(Vector2i(8, 12) in destinations, "unexplored directions gain no extension")
	return true


func test_engineer_extended_reach_requires_path_exploration() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(8, 8))
	var partially_explored := ExplorationProvider.from_tiles([
		Vector2i(8, 7),
		Vector2i(8, 6),
		Vector2i(8, 5),
	])
	var destinations := _destinations(state, engineer, partially_explored)
	assert_eq(destinations.size(), 17, "only the fully explored direction gains extended reach")
	assert_true(Vector2i(8, 5) in destinations, "fully explored path extends north reach")
	assert_false(Vector2i(8, 4) in destinations, "the next unexplored tile stops extended reach")
	assert_true(Vector2i(8, 10) in destinations, "base reach remains available elsewhere")
	assert_false(Vector2i(8, 11) in destinations, "unexplored directions gain no extension")
	return true


func test_scout_cannot_capture() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 5))
	var destinations := _destinations(state, scout, ExplorationProvider.all_explored())
	assert_eq(destinations.size(), 37, "north destinations stop before the enemy")
	assert_false(Vector2i(8, 5) in destinations, "scout cannot enter an enemy tile")
	assert_false(Vector2i(8, 4) in destinations, "scout cannot pass through an enemy")
	assert_true(Vector2i(8, 6) in destinations, "scout stops on the tile before the enemy")

	var result := MovementRules.move_unit(
		state, scout, Vector2i(8, 5), ExplorationProvider.all_explored()
	)
	assert_false(result.success, "scout capture attempt is rejected")
	assert_eq(scout.tile, Vector2i(8, 8), "scout stays in place")
	return true


func test_engineer_cannot_capture() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 6))
	var destinations := _destinations(state, engineer, ExplorationProvider.all_explored())
	assert_eq(destinations.size(), 29, "north destinations stop before the enemy")
	assert_false(Vector2i(8, 6) in destinations, "engineer cannot enter an enemy tile")
	assert_false(Vector2i(8, 5) in destinations, "engineer cannot pass through an enemy")
	assert_true(Vector2i(8, 7) in destinations, "engineer stops on the tile before the enemy")

	var result := MovementRules.move_unit(
		state, engineer, Vector2i(8, 6), ExplorationProvider.all_explored()
	)
	assert_false(result.success, "engineer capture attempt is rejected")
	return true


func test_friendly_unit_blocks_step_move() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 6))
	var destinations := _destinations(state, scout, ExplorationProvider.all_explored())
	assert_eq(destinations.size(), 36, "friendly unit removes the rest of the ray")
	assert_true(Vector2i(8, 7) in destinations, "scout stops before the friendly unit")
	assert_false(Vector2i(8, 6) in destinations, "friendly tile is not a destination")
	assert_false(Vector2i(8, 5) in destinations, "scout cannot pass through a friendly unit")
	return true


func test_scout_move_execution() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	var result := MovementRules.move_unit(
		state, scout, Vector2i(8, 4), ExplorationProvider.all_explored()
	)
	assert_true(result.success, "scout extended move succeeds")
	assert_eq(scout.tile, Vector2i(8, 4), "scout reaches the chosen destination")
	assert_eq(state.get_unit_at(Vector2i(8, 4)).id, scout.id, "occupancy follows the scout")
	assert_false(state.occupancy.has(Vector2i(8, 8)), "old tile is cleared")
	return true


func _destinations(
	state: GameState,
	unit: GameUnit,
	exploration: ExplorationProvider
) -> Array[Vector2i]:
	return MovementRules.legal_destinations(state, unit, exploration)
