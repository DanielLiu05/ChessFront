extends TestCase

const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"


func test_ascii_renderer_shows_phase2_symbols() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "terrain map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	var rendered := AsciiBoardRenderer.render(state)
	assert_true(rendered.contains("f"), "forest symbol")
	assert_true(rendered.contains("^"), "hill symbol")
	assert_true(rendered.contains("~"), "water symbol")
	assert_true(rendered.contains("G"), "gold mine symbol")

	state.board.get_tile(Vector2i(5, 7)).has_bridge = true
	rendered = AsciiBoardRenderer.render(state)
	assert_true(rendered.contains("="), "bridge symbol")
	return true


func test_terrain_map_supports_bridge_and_mine_queries() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "terrain map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	var engineer := MovementTestUtils.add_unit(
		state, UnitType.Type.ENGINEER, GameConfig.Player.PLAYER_1, Vector2i(4, 6)
	)
	var build := ActionResolver.resolve(
		state,
		BuildBridgeAction.new(engineer.id, Vector2i(5, 7)),
		ExplorationProvider.all_explored()
	)
	assert_true(build.success, "bridge can be built on the showcase map")
	assert_true(state.board.get_tile(Vector2i(5, 7)).has_bridge, "bridge state is set")
	assert_eq(state.get_bridge_tiles().size(), 1, "bridge query sees the tile")
	assert_eq(state.gold_mines.size(), 2, "mine objects remain intact")
	assert_true(state.is_gold_mine(Vector2i(5, 6)), "mine query still works")
	return true
