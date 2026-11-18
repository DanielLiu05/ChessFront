extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1


func test_engineer_attempt_stops_at_frontier() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(8, 8)
	)
	MovementTestUtils.clear_knowledge(state)
	state.get_knowledge(PLAYER_1).mark_visible(Vector2i(8, 8))
	var view := PlayerView.for_player(state, PLAYER_1)
	var destination := Vector2i(8, 6)
	var path := DestinationHints.path_tiles(view, engineer, destination)
	assert_eq(path, [Vector2i(8, 7), Vector2i(8, 6)], "path steps toward the target")
	assert_eq(
		DestinationHints.frontier_tile(view, engineer, destination),
		Vector2i(8, 7),
		"first unexplored tile is the frontier"
	)
	assert_true(DestinationHints.is_attempt(view, engineer, destination), "unexplored path is an attempt")
	var split := DestinationHints.preview_split(view, engineer, destination)
	assert_eq((split["solid"] as Array).size(), 0, "nothing is guaranteed past the frontier")
	assert_eq(
		split["uncertain"], [Vector2i(8, 7), Vector2i(8, 6)], "frontier and beyond are uncertain"
	)
	return true


func test_explored_path_is_guaranteed() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(8, 8)
	)
	MovementTestUtils.clear_knowledge(state)
	var knowledge := state.get_knowledge(PLAYER_1)
	for tile: Vector2i in [Vector2i(8, 8), Vector2i(8, 7), Vector2i(8, 6)]:
		knowledge.mark_visible(tile)
	var view := PlayerView.for_player(state, PLAYER_1)
	var destination := Vector2i(8, 6)
	assert_false(DestinationHints.is_attempt(view, engineer, destination), "known path is guaranteed")
	assert_eq(
		DestinationHints.frontier_tile(view, engineer, destination),
		Vector2i(-1, -1),
		"no frontier on a known path"
	)
	var split := DestinationHints.preview_split(view, engineer, destination)
	assert_eq(split["solid"], [Vector2i(8, 7), Vector2i(8, 6)], "all path tiles are solid")
	assert_eq((split["uncertain"] as Array).size(), 0, "no uncertain tiles")
	return true


func test_frontier_tiles_are_unique() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(8, 8)
	)
	MovementTestUtils.clear_knowledge(state)
	state.get_knowledge(PLAYER_1).mark_visible(Vector2i(8, 8))
	var view := PlayerView.for_player(state, PLAYER_1)
	var destinations: Array[Vector2i] = [Vector2i(8, 7), Vector2i(8, 6)]
	var frontiers := DestinationHints.frontier_tiles(view, engineer, destinations)
	assert_eq(frontiers, [Vector2i(8, 7)], "shared frontier is listed once")
	return true
