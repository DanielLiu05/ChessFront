extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)


func test_view_hides_concealed_forest_enemy() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	state.refresh_vision()
	var view := PlayerView.for_player(state, PLAYER_1)
	assert_null(view.get_unit_at(enemy_tile), "concealed enemy is absent from the view")
	assert_false(view.is_occupied(enemy_tile), "concealed enemy does not block the view")
	assert_eq(view.get_known_units().size(), 1, "only the friendly unit is known")
	assert_eq(view.get_unit_at(CENTER).id, rook.id, "friendly unit is always known")
	return true


func test_view_includes_detected_forest_enemy() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	var enemy := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	state.refresh_vision()
	var view := PlayerView.for_player(state, PLAYER_1)
	assert_not_null(view.get_unit_at(enemy_tile), "Scout detects the forest enemy")
	if view.get_unit_at(enemy_tile) != null:
		assert_eq(view.get_unit_at(enemy_tile).id, enemy.id, "detected enemy id")
	return true


func test_view_treats_unexplored_tiles_as_ground() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var unknown_tile := Vector2i(8, 4)
	var known_tile := Vector2i(8, 6)
	state.board.get_tile(unknown_tile).terrain = TerrainType.Type.WATER
	state.board.get_tile(known_tile).terrain = TerrainType.Type.FOREST
	state.refresh_vision()
	var view := PlayerView.for_player(state, PLAYER_1)
	assert_eq(view.board.get_tile(unknown_tile).terrain, TerrainType.Type.GROUND, "unexplored tile is ground")
	assert_true(view.board.is_passable(unknown_tile), "unexplored tile is passable")
	assert_false(view.exploration.is_explored(unknown_tile), "unknown tile is not explored")
	assert_eq(view.board.get_tile(known_tile).terrain, TerrainType.Type.FOREST, "explored terrain is known")
	assert_true(view.board.is_passable(known_tile), "known forest is passable")
	assert_true(view.exploration.is_explored(known_tile), "known tile is explored")
	assert_false(state.board.is_passable(unknown_tile), "authoritative water remains impassable")
	return true


func test_highlights_treat_concealed_enemy_as_absent() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	state.board.get_tile(enemy_tile).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	state.refresh_vision()
	var view := PlayerView.for_player(state, PLAYER_1)
	var destinations := MovementRules.legal_destinations(view, rook, view.exploration)
	assert_null(view.get_unit_at(enemy_tile), "enemy remains hidden")
	assert_true(enemy_tile in destinations, "highlight treats the concealed enemy as absent")
	return true


func test_known_enemy_is_capturable_and_blocks_beyond() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var enemy_tile := Vector2i(8, 6)
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, enemy_tile)
	state.refresh_vision()
	var view := PlayerView.for_player(state, PLAYER_1)
	var destinations := MovementRules.legal_destinations(view, rook, view.exploration)
	assert_true(enemy_tile in destinations, "known enemy is a capture destination")
	assert_false(Vector2i(8, 5) in destinations, "highlight stops at the known enemy")
	return true


func test_sliding_frontier_reach_matches_vision() -> bool:
	var ground_state := _clean_state()
	assert_not_null(ground_state, "ground state built")
	if ground_state == null:
		return true
	var ground_rook := MovementTestUtils.add_unit(ground_state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	ground_state.refresh_vision()
	var ground_view := PlayerView.for_player(ground_state, PLAYER_1)
	var ground_destinations := MovementRules.legal_destinations(
		ground_view, ground_rook, ground_view.exploration
	)
	assert_true(Vector2i(8, 6) in ground_destinations, "rook reaches its two-tile frontier")
	assert_false(Vector2i(8, 5) in ground_destinations, "rook cannot highlight beyond the frontier")

	var hill_state := _clean_state()
	assert_not_null(hill_state, "hill state built")
	if hill_state == null:
		return true
	hill_state.board.get_tile(CENTER).terrain = TerrainType.Type.HILL
	var hill_rook := MovementTestUtils.add_unit(hill_state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	hill_state.refresh_vision()
	var hill_view := PlayerView.for_player(hill_state, PLAYER_1)
	var hill_destinations := MovementRules.legal_destinations(
		hill_view, hill_rook, hill_view.exploration
	)
	assert_true(Vector2i(8, 5) in hill_destinations, "hill rook reaches its three-tile frontier")
	assert_false(Vector2i(8, 4) in hill_destinations, "hill rook cannot highlight beyond the frontier")
	return true


func test_sliding_reach_is_unlimited_along_explored_ground() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(7, 3))
	state.refresh_vision()
	var view := PlayerView.for_player(state, PLAYER_1)
	var destinations := MovementRules.legal_destinations(view, rook, view.exploration)
	assert_true(Vector2i(8, 0) in destinations, "rook moves through contiguous explored ground")
	return true


func test_scout_extended_reach_uses_player_exploration() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var scout := MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(7, 2))
	state.refresh_vision()
	var view := PlayerView.for_player(state, PLAYER_1)
	var destinations := MovementRules.legal_destinations(view, scout, view.exploration)
	assert_true(Vector2i(8, 3) in destinations, "extended scout reach uses explored path tiles")
	assert_false(Vector2i(8, 2) in destinations, "scout cannot exceed its explored reach")
	return true


func test_friendly_units_are_known_and_block() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var friendly := MovementTestUtils.add_unit(
		state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 6)
	)
	state.refresh_vision()
	var view := PlayerView.for_player(state, PLAYER_1)
	assert_eq(view.get_unit_at(friendly.tile).id, friendly.id, "friendly unit is known")
	var destinations := MovementRules.legal_destinations(view, rook, view.exploration)
	assert_false(Vector2i(8, 6) in destinations, "friendly unit blocks the highlight")
	return true


func test_player_views_are_independent() -> bool:
	var state := _clean_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, CENTER)
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 4))
	state.refresh_vision()
	var p1_view := PlayerView.for_player(state, PLAYER_1)
	var p2_view := PlayerView.for_player(state, PLAYER_2)
	assert_not_null(p1_view.get_unit_at(CENTER), "player 1 sees its rook")
	assert_null(p1_view.get_unit_at(pawn.tile), "player 1 cannot see the distant pawn")
	assert_not_null(p2_view.get_unit_at(pawn.tile), "player 2 sees its pawn")
	assert_null(p2_view.get_unit_at(CENTER), "player 2 cannot see the distant rook")
	return true


func _clean_state() -> GameState:
	var state := MovementTestUtils.empty_state()
	if state == null:
		return null
	MovementTestUtils.clear_knowledge(state)
	return state
