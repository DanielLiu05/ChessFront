extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)


func test_vision_area_matches_effective_radius() -> bool:
	assert_eq(_visible_count(UnitType.Type.PAWN, TerrainType.Type.GROUND), 25, "pawn ground 5x5")
	assert_eq(_visible_count(UnitType.Type.PAWN, TerrainType.Type.HILL), 49, "pawn hill 7x7")
	assert_eq(_visible_count(UnitType.Type.PAWN, TerrainType.Type.FOREST), 9, "pawn forest 3x3")
	assert_eq(_visible_count(UnitType.Type.SCOUT, TerrainType.Type.GROUND), 49, "scout ground 7x7")
	assert_eq(_visible_count(UnitType.Type.SCOUT, TerrainType.Type.WATER), 25, "scout water 5x5")
	return true


func test_forest_conceals_from_distant_ordinary_unit() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	state.refresh_vision()
	var knowledge := state.get_knowledge(PLAYER_1)
	assert_true(knowledge.is_visible(enemy_tile), "forest tile itself is visible")
	assert_false(knowledge.is_enemy_detected(enemy.id), "distant ordinary unit does not detect the forest enemy")
	assert_true(knowledge.is_visible(rook.tile), "observer tile is visible")
	return true


func test_forest_detection_distances() -> bool:
	var adjacent_state := _clean_state()
	assert_not_null(adjacent_state, "adjacent state built")
	if adjacent_state == null:
		return true
	MovementTestUtils.add_unit(adjacent_state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var adjacent_tile := Vector2i(8, 7)
	adjacent_state.board.get_tile(adjacent_tile).terrain = TerrainType.Type.FOREST
	var adjacent_enemy := MovementTestUtils.add_unit(adjacent_state, UnitType.Type.PAWN, PLAYER_2, adjacent_tile)
	adjacent_state.refresh_vision()
	assert_true(
		adjacent_state.get_knowledge(PLAYER_1).is_enemy_detected(adjacent_enemy.id),
		"ordinary unit detects a forest enemy at distance 1"
	)

	var scout_state := _clean_state()
	assert_not_null(scout_state, "scout state built")
	if scout_state == null:
		return true
	MovementTestUtils.add_unit(scout_state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var scout_tile := Vector2i(8, 6)
	scout_state.board.get_tile(scout_tile).terrain = TerrainType.Type.FOREST
	var scout_enemy := MovementTestUtils.add_unit(scout_state, UnitType.Type.PAWN, PLAYER_2, scout_tile)
	scout_state.refresh_vision()
	assert_true(
		scout_state.get_knowledge(PLAYER_1).is_enemy_detected(scout_enemy.id),
		"Scout detects a forest enemy at distance 2"
	)

	var distant_state := _clean_state()
	assert_not_null(distant_state, "distant state built")
	if distant_state == null:
		return true
	MovementTestUtils.add_unit(distant_state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var distant_tile := Vector2i(8, 5)
	distant_state.board.get_tile(distant_tile).terrain = TerrainType.Type.FOREST
	var distant_enemy := MovementTestUtils.add_unit(distant_state, UnitType.Type.PAWN, PLAYER_2, distant_tile)
	distant_state.refresh_vision()
	assert_false(
		distant_state.get_knowledge(PLAYER_1).is_enemy_detected(distant_enemy.id),
		"Scout does not detect a forest enemy at distance 3"
	)
	return true


func test_non_forest_enemy_visibility_uses_vision() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var visible_enemy := MovementTestUtils.add_unit(
		state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 6)
	)
	var hidden_enemy := MovementTestUtils.add_unit(
		state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 4)
	)
	state.refresh_vision()
	var knowledge := state.get_knowledge(PLAYER_1)
	assert_true(knowledge.is_enemy_detected(visible_enemy.id), "enemy inside vision is detected")
	assert_false(knowledge.is_enemy_detected(hidden_enemy.id), "enemy outside vision is hidden")
	return true


func test_exploration_persists_after_movement() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	state.refresh_vision()
	var old_tile := Vector2i(8, 11)
	assert_true(state.get_knowledge(PLAYER_1).is_visible(old_tile), "old tile starts visible")
	MovementTestUtils.relocate_unit(state, scout, Vector2i(1, 8))
	state.refresh_vision()
	var knowledge := state.get_knowledge(PLAYER_1)
	assert_true(knowledge.is_explored(old_tile), "old tile stays explored")
	assert_false(knowledge.is_visible(old_tile), "old tile is no longer visible")
	assert_true(knowledge.is_visible(Vector2i(1, 8)), "new tile is visible")
	assert_true(state.get_knowledge(PLAYER_2).visible.is_empty(), "player 2 knowledge is independent")
	return true


func test_enemy_disappears_when_out_of_vision() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 6))
	state.refresh_vision()
	assert_true(
		state.get_knowledge(PLAYER_1).is_enemy_detected(enemy.id),
		"enemy starts detected"
	)
	MovementTestUtils.relocate_unit(state, enemy, Vector2i(8, 4))
	state.refresh_vision()
	assert_false(
		state.get_knowledge(PLAYER_1).is_enemy_detected(enemy.id),
		"enemy is no longer detected"
	)
	assert_true(state.get_knowledge(PLAYER_1).is_visible(Vector2i(8, 6)), "old tile remains visible")
	return true


func test_players_have_independent_vision() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var p1_unit := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var p2_unit := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 4))
	state.refresh_vision()
	var p1_knowledge := state.get_knowledge(PLAYER_1)
	var p2_knowledge := state.get_knowledge(PLAYER_2)
	assert_true(p1_knowledge.is_visible(Vector2i(8, 10)), "player 1 sees its own area")
	assert_false(p1_knowledge.is_visible(Vector2i(8, 2)), "player 1 does not see player 2's area")
	assert_true(p2_knowledge.is_visible(Vector2i(8, 2)), "player 2 sees its own area")
	assert_false(p2_knowledge.is_visible(Vector2i(8, 10)), "player 2 does not see player 1's area")
	assert_false(p1_knowledge.is_enemy_detected(p2_unit.id), "player 1 does not detect the distant enemy")
	assert_false(p2_knowledge.is_enemy_detected(p1_unit.id), "player 2 does not detect the distant enemy")
	return true


func _visible_count(unit_type: int, terrain: TerrainType.Type) -> int:
	var state := _clean_state()
	if state == null:
		return -1
	state.board.get_tile(CENTER).terrain = terrain
	MovementTestUtils.add_unit(state, unit_type, PLAYER_1, CENTER)
	state.refresh_vision()
	return state.get_knowledge(PLAYER_1).visible.size()


func _clean_state() -> GameState:
	var state := MovementTestUtils.empty_state()
	if state == null:
		return null
	MovementTestUtils.clear_knowledge(state)
	return state
