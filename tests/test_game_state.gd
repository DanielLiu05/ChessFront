extends TestCase

const MAP_PATH: String = "res://maps/standard_template.json"


func test_initial_state() -> bool:
	var state := _load_state()
	assert_not_null(state, "state is built")
	if state == null:
		return true
	assert_eq(state.map_id, "standard_template", "map id")
	assert_eq(state.map_format_version, MapData.FORMAT_VERSION, "map version")
	assert_eq(state.active_player, GameConfig.Player.PLAYER_1, "player 1 active")
	assert_eq(state.ply, 0, "ply counter starts at zero")
	assert_false(state.game_over, "game is not over")
	assert_eq(state.winner, GameConfig.NO_PLAYER, "no winner")
	assert_eq(state.get_all_units().size(), 32, "32 units")
	assert_eq(state.count_units_for_player(GameConfig.Player.PLAYER_1), 16, "player 1 units")
	assert_eq(state.count_units_for_player(GameConfig.Player.PLAYER_2), 16, "player 2 units")
	return true


func test_each_side_has_one_king() -> bool:
	var state := _load_state()
	assert_not_null(state, "state is built")
	if state == null:
		return true
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var kings := 0
		for unit: GameUnit in state.get_units_for_player(player):
			if unit.type == UnitType.Type.KING:
				kings += 1
		assert_eq(kings, 1, "player %d has one king" % player)
	return true


func test_starting_positions_match_map() -> bool:
	var result := MapIO.load_from_file(MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(result.map)
	var expected: Dictionary[String, int] = {}
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		for entry: MapStartingUnit in result.map.get_starting_units(player):
			expected[_unit_key(player, entry.tile)] = entry.type
	assert_eq(expected.size(), 32, "expected unit positions")
	for unit: GameUnit in state.get_all_units():
		var key := _unit_key(unit.owner, unit.tile)
		assert_true(expected.has(key), "unit at %s is defined by the map" % str(unit.tile))
		assert_eq(unit.type, expected[key], "unit type at %s matches the map" % str(unit.tile))
	return true


func test_occupancy_matches_units() -> bool:
	var state := _load_state()
	assert_not_null(state, "state is built")
	if state == null:
		return true
	assert_eq(state.occupancy.size(), 32, "occupancy index size")
	for unit: GameUnit in state.get_all_units():
		var tile := state.board.get_tile(unit.tile)
		assert_eq(tile.occupant_id, unit.id, "tile occupant for unit %d" % unit.id)
		assert_true(state.is_occupied(unit.tile), "tile reports occupied")
		assert_eq(state.get_unit_at(unit.tile).id, unit.id, "unit lookup by tile")
	return true


func test_unit_ids_are_deterministic() -> bool:
	var result := MapIO.load_from_file(MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var first := GameState.new(result.map)
	var second := GameState.new(result.map)
	assert_eq(first.snapshot_text(), second.snapshot_text(), "snapshots are deterministic")
	var ids := first.units.keys()
	ids.sort()
	assert_eq(ids.size(), 32, "32 ids")
	assert_eq(ids[0], 1, "first id")
	assert_eq(ids[ids.size() - 1], 32, "last id")
	return true


func test_configured_first_player() -> bool:
	var result := MapIO.load_from_file(MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(
		result.map,
		GameConfig.DEFAULT_TURN_LIMIT_PLIES,
		GameConfig.Player.PLAYER_2
	)
	assert_eq(state.active_player, GameConfig.Player.PLAYER_2, "player 2 starts active")
	assert_eq(state.ply, 0, "ply starts at zero")
	assert_eq(
		int(state.snapshot()["active_player"]),
		GameConfig.Player.PLAYER_2,
		"snapshot keeps the configured first player"
	)
	TurnManager.advance_turn(state)
	assert_eq(
		state.active_player,
		GameConfig.Player.PLAYER_1,
		"turn order continues from the configured first player"
	)
	var default_state := GameState.new(result.map)
	assert_eq(
		default_state.active_player,
		GameConfig.Player.PLAYER_1,
		"the default remains player 1"
	)
	return true


func test_game_state_does_not_mutate_map_board() -> bool:
	var result := MapIO.load_from_file(MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var map := result.map
	var state := GameState.new(map)
	assert_eq(state.get_all_units().size(), 32, "units deployed")
	for unit: GameUnit in state.get_all_units():
		assert_eq(map.board.get_tile(unit.tile).occupant_id, BoardTileData.NO_OCCUPANT, "map board stays unoccupied")
	return true


func _load_state() -> GameState:
	var result := MapIO.load_from_file(MAP_PATH)
	if not result.is_valid():
		push_error("Could not load map: %s" % str(result.errors))
		return null
	return GameState.new(result.map)


func _unit_key(player: int, tile: Vector2i) -> String:
	return "%d|%d|%d" % [player, tile.x, tile.y]
