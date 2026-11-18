extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const STANDARD_MAP_PATH: String = "res://maps/standard_template.json"


func test_view_round_trip_excludes_hidden_state() -> bool:
	var loaded := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(loaded.is_valid(), "terrain map loads")
	if not loaded.is_valid():
		return true
	var state := GameState.new(loaded.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.clear_gold(state)
	MovementTestUtils.reset_knowledge(state)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	var visible_enemy := MovementTestUtils.add_unit(
		state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 9)
	)
	var hidden_enemy := MovementTestUtils.add_unit(
		state, UnitType.Type.QUEEN, PLAYER_2, Vector2i(0, 8)
	)
	state.board.get_tile(Vector2i(8, 7)).has_bridge = true
	state.get_gold_mine_at(Vector2i(10, 9)).gold_available = true
	state.add_gold(PLAYER_1, 3)
	state.add_gold(PLAYER_2, 9)
	state.refresh_vision()

	var view := PlayerView.for_player(state, PLAYER_1)
	var data := NetworkViewCodec.encode(state, view, PLAYER_1)
	assert_false(data.is_empty(), "view encodes")
	assert_eq(String(data["map_id"]), loaded.map.id, "map id")
	assert_eq(int(data["local_player"]), PLAYER_1, "local player")
	assert_eq(int(data["own_gold"]), 3, "own gold")
	assert_false(data.has("enemy_gold"), "enemy gold field is absent")
	assert_false(data.has("player_gold"), "raw player-gold field is absent")
	assert_true(_has_unit(data["units"], visible_enemy.id), "visible enemy is present")
	assert_false(_has_unit(data["units"], hidden_enemy.id), "hidden enemy is absent")
	assert_true(_has_tile(data["bridges"], Vector2i(8, 7)), "known bridge is present")
	assert_true(_has_tile(data["known_mines"], Vector2i(10, 9)), "visible mine is known")
	assert_true(
		_has_tile(data["visible_gold_tokens"], Vector2i(10, 9)),
		"visible token is marked"
	)
	assert_eq(data, NetworkViewCodec.encode(state, view, PLAYER_1), "encoding is deterministic")

	assert_true(NetworkViewCodec.validate(data, loaded.map).is_empty(), "view validates")
	var decoded := NetworkViewCodec.decode(data, loaded.map)
	assert_not_null(decoded, "view decodes")
	if decoded != null:
		assert_eq(decoded.player, PLAYER_1, "decoded player")
		assert_true(decoded.knowledge.is_explored(Vector2i(8, 8)), "decoded exploration")
		assert_true(decoded.knowledge.is_visible(Vector2i(8, 9)), "decoded visibility")
		assert_true(decoded.board.get_tile(Vector2i(8, 7)).has_bridge, "decoded bridge")
		assert_true(decoded.known_units.has(visible_enemy.id), "decoded visible enemy")
		assert_true(
			decoded.knowledge.is_enemy_detected(visible_enemy.id),
			"decoded detected enemy"
		)
		assert_false(decoded.known_units.has(hidden_enemy.id), "decoded hidden enemy is absent")
	return true


func test_view_rejects_wrong_map_and_malformed_data() -> bool:
	var loaded := MapIO.load_from_file(TERRAIN_MAP_PATH)
	var other := MapIO.load_from_file(STANDARD_MAP_PATH)
	assert_true(loaded.is_valid(), "terrain map loads")
	assert_true(other.is_valid(), "standard map loads")
	if not loaded.is_valid() or not other.is_valid():
		return true
	var state := GameState.new(loaded.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.clear_gold(state)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8))
	state.refresh_vision()
	var data := NetworkViewCodec.encode(state, PlayerView.for_player(state, PLAYER_1), PLAYER_1)
	assert_false(NetworkViewCodec.validate(data, other.map).is_empty(), "wrong map is rejected")
	assert_null(NetworkViewCodec.decode(data, other.map), "wrong map does not decode")

	var missing_gold := data.duplicate(true)
	missing_gold.erase("own_gold")
	assert_false(NetworkViewCodec.validate(missing_gold, loaded.map).is_empty(), "missing gold rejected")
	var bad_units := data.duplicate(true)
	bad_units["units"] = [{"id": 1, "type": 99, "owner": PLAYER_1, "tile": [8, 8]}]
	assert_false(NetworkViewCodec.validate(bad_units, loaded.map).is_empty(), "bad unit type rejected")
	var bad_tiles := data.duplicate(true)
	bad_tiles["visible"] = [[0, 0]]
	bad_tiles["explored"] = []
	assert_false(NetworkViewCodec.validate(bad_tiles, loaded.map).is_empty(), "unexplored visibility rejected")
	return true


func _has_unit(entries: Array, unit_id: int) -> bool:
	for entry: Dictionary in entries:
		if int(entry["id"]) == unit_id:
			return true
	return false


func _has_tile(entries: Array, tile: Vector2i) -> bool:
	for entry: Array in entries:
		if int(entry[0]) == tile.x and int(entry[1]) == tile.y:
			return true
	return false
