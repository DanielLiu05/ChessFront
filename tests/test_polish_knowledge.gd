extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1


func test_explored_tile_keeps_last_seen_terrain_and_bridge() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var observer := MovementTestUtils.add_unit(
		state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 8)
	)
	state.refresh_vision()
	var watched := Vector2i(8, 6)
	var knowledge := state.get_knowledge(PLAYER_1)
	assert_true(knowledge.is_visible(watched), "watched tile starts visible")

	state.board.get_tile(watched).terrain = TerrainType.Type.FOREST
	state.board.get_tile(watched).has_bridge = true
	state.refresh_vision()
	var visible_view := PlayerView.for_player(state, PLAYER_1)
	assert_eq(
		visible_view.board.get_tile(watched).terrain,
		TerrainType.Type.FOREST,
		"visible tile shows live terrain"
	)
	assert_true(visible_view.board.get_tile(watched).has_bridge, "visible tile shows live bridge")

	MovementTestUtils.relocate_unit(state, observer, Vector2i(0, 0))
	state.refresh_vision()
	assert_false(knowledge.is_visible(watched), "watched tile is now fogged")
	assert_true(knowledge.is_explored(watched), "watched tile stays explored")

	state.board.get_tile(watched).terrain = TerrainType.Type.WATER
	state.board.get_tile(watched).has_bridge = false
	state.refresh_vision()
	var fogged_view := PlayerView.for_player(state, PLAYER_1)
	assert_eq(
		fogged_view.board.get_tile(watched).terrain,
		TerrainType.Type.FOREST,
		"fogged tile keeps last-seen terrain"
	)
	assert_true(
		fogged_view.board.get_tile(watched).has_bridge,
		"fogged tile keeps last-seen bridge"
	)
	return true


func test_known_tile_snapshot_is_sorted_and_deterministic() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	state.refresh_vision()
	var knowledge := state.get_knowledge(PLAYER_1)
	var first: Array = knowledge.to_snapshot()["known_tiles"]
	var second: Array = knowledge.to_snapshot()["known_tiles"]
	assert_true(first.size() > 0, "visible tiles are remembered")
	assert_eq(first, second, "known-tile snapshot is deterministic")
	for index in range(1, first.size()):
		var previous: Array = first[index - 1]
		var current: Array = first[index]
		assert_true(
			previous[1] < current[1] or (previous[1] == current[1] and previous[0] <= current[0]),
			"known tiles are sorted by row then column"
		)
	return true
