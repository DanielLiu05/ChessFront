extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2


func test_observation_contains_only_player_knowledge() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	var mine := GoldMine.new(Vector2i(8, 5))
	mine.gold_available = true
	state.gold_mines.append(mine)
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 1))
	state.refresh_vision()

	var observation := AiObservation.for_player(state, PLAYER_1)
	assert_eq(observation.player, PLAYER_1, "observation player")
	assert_eq(observation.view.player, PLAYER_1, "view player")
	assert_eq(observation.gold, state.get_gold(PLAYER_1), "own gold")
	assert_eq(observation.turn_limit_plies, state.turn_limit_plies, "public turn limit")
	assert_eq(observation.ply, state.ply, "public ply")
	assert_eq(observation.map_id, state.map_id, "map id")
	assert_eq(observation.view.get_known_units().size(), 1, "only the friendly unit is known")
	assert_null(observation.view.get_unit_at(Vector2i(8, 1)), "hidden enemy is absent")
	assert_eq(
		observation.view.deployment_tiles.size(),
		state.get_deployment_tiles(PLAYER_1).size(),
		"own deployment is known"
	)
	assert_true(mine.tile in observation.view.known_mines, "explored mine is known")
	assert_true(
		mine.tile in observation.view.visible_gold_token_tiles,
		"visible gold token is known"
	)
	return true


func test_observation_excludes_unexplored_mine() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	var mine := GoldMine.new(Vector2i(0, 8))
	mine.gold_available = true
	state.gold_mines.append(mine)
	state.refresh_vision()
	var observation := AiObservation.for_player(state, PLAYER_1)
	assert_false(mine.tile in observation.view.known_mines, "unexplored mine is absent")
	assert_false(
		mine.tile in observation.view.visible_gold_token_tiles,
		"unexplored token is absent"
	)
	return true


func test_observation_does_not_include_enemy_gold() -> bool:
	var state := _empty_state()
	if state == null:
		return true
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	state.add_gold(PLAYER_1, 3)
	state.add_gold(PLAYER_2, 7)
	state.refresh_vision()
	var observation := AiObservation.for_player(state, PLAYER_1)
	assert_eq(observation.gold, 3, "AI sees its own gold")
	assert_false("enemy_gold" in observation, "observation has no enemy gold field")
	return true


func _empty_state() -> GameState:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "empty state exists")
	return state
