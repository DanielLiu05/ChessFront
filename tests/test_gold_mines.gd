extends TestCase

const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"


func test_terrain_map_creates_mine_objects() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	assert_eq(state.gold_mines.size(), 2, "two gold mines")
	for tile: Vector2i in [Vector2i(5, 6), Vector2i(10, 9)]:
		assert_true(state.is_gold_mine(tile), "mine exists at %s" % str(tile))
		var mine := state.get_gold_mine_at(tile)
		assert_not_null(mine, "mine object at %s" % str(tile))
		if mine != null:
			assert_eq(mine.tile, tile, "mine tile")
	assert_false(state.is_gold_mine(Vector2i(8, 8)), "ordinary ground is not a mine")
	return true


func test_mine_is_passable_and_occupiable() -> bool:
	var state := _terrain_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.clear_units(state)
	var mine_tile := Vector2i(5, 6)
	assert_true(state.board.is_passable(mine_tile), "mine tile is passable")
	var pawn := MovementTestUtils.add_unit(state, UnitType.Type.PAWN, GameConfig.Player.PLAYER_1, mine_tile)
	assert_eq(state.get_unit_at(mine_tile).id, pawn.id, "unit occupies the mine")
	assert_true(state.is_gold_mine(mine_tile), "occupied tile remains a mine")
	return true


func test_snapshot_includes_sorted_mines() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var first := GameState.new(result.map)
	var second := GameState.new(result.map)
	var mines: Array = first.snapshot()["gold_mines"]
	assert_eq(mines.size(), 2, "snapshot contains two mines")
	var first_mine: Dictionary = mines[0]
	var second_mine: Dictionary = mines[1]
	var first_tile: Array = first_mine["tile"]
	var second_tile: Array = second_mine["tile"]
	assert_eq(int(first_tile[0]), 5, "first mine x")
	assert_eq(int(first_tile[1]), 6, "first mine y")
	assert_eq(int(second_tile[0]), 10, "second mine x")
	assert_eq(int(second_tile[1]), 9, "second mine y")
	assert_eq(int(first_mine["cycle_progress"]), 0, "first mine starts at cycle 0")
	assert_false(first_mine["gold_available"], "first mine starts without a token")
	assert_eq(first.snapshot_text(), second.snapshot_text(), "mine snapshot is deterministic")
	return true


func test_mine_on_water_is_rejected() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var map := result.map
	map.gold_mines.assign([Vector2i(5, 7), Vector2i(10, 8)])
	var errors := MapValidator.validate(map)
	assert_true(not errors.is_empty(), "water mines are rejected")
	assert_true(_errors_contain(errors, "not passable"), "water mine error is clear")
	return true


func test_deployment_on_water_is_rejected() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var map := result.map
	var tile := Vector2i(4, 14)
	map.board.get_tile(tile).terrain = TerrainType.Type.WATER
	map.board.get_tile(GameConfig.mirror_tile(tile)).terrain = TerrainType.Type.WATER
	var errors := MapValidator.validate(map)
	assert_true(not errors.is_empty(), "water deployment is rejected")
	assert_true(_errors_contain(errors, "not passable"), "deployment water error is clear")
	return true


func _terrain_state() -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load terrain map: %s" % str(result.errors))
		return null
	return GameState.new(result.map)


func _errors_contain(errors: Array[String], needle: String) -> bool:
	for error: String in errors:
		if error.contains(needle):
			return true
	return false
