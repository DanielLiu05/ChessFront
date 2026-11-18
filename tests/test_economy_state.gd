extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const MAP_PATH: String = "res://maps/standard_template.json"
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"


func test_players_start_with_configured_gold() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	assert_eq(state.get_gold(PLAYER_1), GameConfig.STARTING_GOLD, "player 1 starts with configured gold")
	assert_eq(state.get_gold(PLAYER_2), GameConfig.STARTING_GOLD, "player 2 starts with configured gold")
	assert_eq(state.get_gold(PLAYER_1), 2, "starting gold is two")
	state.add_gold(PLAYER_1, 5)
	assert_eq(state.get_gold(PLAYER_1), 7, "gold can be added")
	assert_true(state.spend_gold(PLAYER_1, 2), "gold can be spent")
	assert_eq(state.get_gold(PLAYER_1), 5, "spending deducts gold")
	assert_false(state.spend_gold(PLAYER_1, 6), "insufficient gold is rejected")
	assert_eq(state.get_gold(PLAYER_1), 5, "failed spend leaves gold unchanged")
	assert_false(state.spend_gold(PLAYER_1, -1), "negative spend is rejected")
	state.add_gold(PLAYER_1, -5)
	assert_eq(state.get_gold(PLAYER_1), 5, "negative add is ignored")
	return true


func test_deployment_tiles_match_map() -> bool:
	var result := MapIO.load_from_file(MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(result.map)
	for player: int in [PLAYER_1, PLAYER_2]:
		var state_tiles := state.get_deployment_tiles(player)
		var map_tiles := result.map.get_deployment_tiles(player)
		assert_eq(state_tiles.size(), 18, "deployment tile count")
		assert_eq(state_tiles, map_tiles, "deployment tiles match the map")
	assert_true(state.is_deployment_tile(PLAYER_1, Vector2i(3, 14)), "player 1 deployment tile")
	assert_true(state.is_deployment_tile(PLAYER_2, Vector2i(12, 1)), "player 2 deployment tile")
	assert_false(state.is_deployment_tile(PLAYER_1, Vector2i(8, 8)), "center is not a deployment tile")
	return true


func test_mine_state_and_derived_occupancy() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "terrain map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(result.map)
	assert_eq(state.gold_mines.size(), 2, "two mines are present")
	for mine: GoldMine in state.gold_mines:
		assert_eq(mine.cycle_progress, 0, "mine starts at cycle 0")
		assert_false(mine.gold_available, "mine starts without a token")
		assert_null(state.get_mine_occupant(mine), "mine starts unoccupied")
		assert_eq(state.get_mine_owner(mine), GameConfig.NO_PLAYER, "mine starts ownerless")

	var mine := state.get_gold_mine_at(Vector2i(5, 6))
	assert_not_null(mine, "known mine exists")
	if mine == null:
		return true
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, mine.tile)
	assert_eq(state.get_mine_occupant(mine).id, pawn.id, "occupant is derived from the tile")
	assert_eq(state.get_mine_owner(mine), int(PLAYER_1), "owner is derived from the occupant")
	return true


func test_unit_ids_continue_after_deployment() -> bool:
	var state := _deployed_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	assert_eq(state.next_unit_id, 33, "next id follows the initial 32 units")
	var unit := state.create_unit(UnitType.Type.PAWN, PLAYER_1, Vector2i(3, 14))
	assert_eq(unit.id, 33, "new unit id")
	assert_eq(state.next_unit_id, 34, "next id advances")
	assert_eq(state.get_unit_at(Vector2i(3, 14)).id, unit.id, "new unit occupies its tile")
	return true


func _deployed_state() -> GameState:
	var result := MapIO.load_from_file(MAP_PATH)
	if not result.is_valid():
		push_error("Could not load economy test map: %s" % str(result.errors))
		return null
	return GameState.new(result.map)
