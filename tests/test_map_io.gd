extends TestCase

const STANDARD_MAP_PATH: String = "res://maps/standard_template.json"
const VARIANT_MAP_PATH: String = "res://maps/variant_layout.json"
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"


func test_standard_map_loads() -> bool:
	var result := MapIO.load_from_file(STANDARD_MAP_PATH)
	assert_true(result.is_valid(), "standard map is valid: %s" % str(result.errors))
	if not result.is_valid():
		return true
	var map := result.map
	assert_eq(map.id, "standard_template", "map id")
	assert_eq(map.format_version, MapData.FORMAT_VERSION, "format version")
	assert_eq(map.board.playable_count(), 216, "board tiles")
	assert_eq(map.get_starting_units(GameConfig.Player.PLAYER_1).size(), 16, "player 1 unit count")
	assert_eq(map.get_starting_units(GameConfig.Player.PLAYER_2).size(), 16, "player 2 unit count")
	assert_eq(map.get_deployment_tiles(GameConfig.Player.PLAYER_1).size(), 18, "player 1 deployment tiles")
	assert_eq(map.get_deployment_tiles(GameConfig.Player.PLAYER_2).size(), 18, "player 2 deployment tiles")
	return true


func test_variant_map_loads() -> bool:
	var result := MapIO.load_from_file(VARIANT_MAP_PATH)
	assert_true(result.is_valid(), "variant map is valid: %s" % str(result.errors))
	if not result.is_valid():
		return true
	assert_eq(result.map.id, "variant_layout", "variant map id")
	assert_eq(result.map.get_starting_units(GameConfig.Player.PLAYER_1).size(), 16, "variant player 1 unit count")
	return true


func test_terrain_showcase_loads() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "terrain map is valid: %s" % str(result.errors))
	if not result.is_valid():
		return true
	var map := result.map
	assert_eq(map.id, "terrain_showcase", "terrain map id")
	assert_eq(map.gold_mines.size(), 2, "terrain map has two mines")
	var terrain_counts: Dictionary[int, int] = {}
	for tile: Vector2i in map.board.get_playable_tiles():
		var terrain: int = map.board.get_tile(tile).terrain
		terrain_counts[terrain] = int(terrain_counts.get(terrain, 0)) + 1
	for terrain_type: int in TerrainRegistry.get_all_types():
		assert_true(int(terrain_counts.get(terrain_type, 0)) > 0, "terrain type %d is present" % terrain_type)
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		for unit: MapStartingUnit in map.get_starting_units(player):
			assert_eq(
				map.board.get_tile(unit.tile).terrain,
				TerrainType.Type.GROUND,
				"starting unit is on ground"
			)
		for tile: Vector2i in map.get_deployment_tiles(player):
			assert_eq(
				map.board.get_tile(tile).terrain,
				TerrainType.Type.GROUND,
				"deployment tile is on ground"
			)
	for mine_tile: Vector2i in map.gold_mines:
		assert_ne(
			map.board.get_tile(mine_tile).terrain,
			TerrainType.Type.WATER,
			"gold mine is on land"
		)
	return true


func test_round_trip_is_byte_identical() -> bool:
	var text := FileAccess.get_file_as_string(STANDARD_MAP_PATH)
	var result := MapIO.load_from_text(text)
	assert_true(result.is_valid(), "round-trip source is valid")
	if not result.is_valid():
		return true
	assert_eq(MapIO.to_json_text(result.map), text, "canonical round-trip")
	return true


func test_wrong_version_is_rejected() -> bool:
	var data := _valid_map_data()
	data["format_version"] = 999
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "wrong version is rejected")
	assert_true(_has_error(result, "version"), "version error is clear")
	return true


func test_malformed_json_is_rejected() -> bool:
	var result := MapIO.load_from_text("{ this is not json")
	assert_false(result.is_valid(), "malformed JSON is rejected")
	assert_true(_has_error(result, "JSON"), "JSON error is clear")
	return true


func test_missing_field_is_rejected() -> bool:
	var data := _valid_map_data()
	data.erase("id")
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "missing id is rejected")
	assert_true(_has_error(result, "id"), "id error is clear")
	return true


func test_unknown_terrain_is_rejected() -> bool:
	var data := _valid_map_data()
	var terrain: Array = data["terrain"] as Array
	var row: Array = terrain[4] as Array
	row[0] = "lava"
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "unknown terrain is rejected")
	assert_true(_has_error(result, "Unknown terrain"), "terrain error is clear")
	return true


func test_asymmetric_mask_is_rejected() -> bool:
	var data := _valid_map_data()
	var terrain: Array = data["terrain"] as Array
	var row: Array = terrain[0] as Array
	row[0] = "ground"
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "asymmetric mask is rejected")
	return true


func test_asymmetric_elevation_is_rejected() -> bool:
	var data := _valid_map_data()
	var elevation: Array = data["elevation"] as Array
	var row: Array = elevation[8] as Array
	row[8] = 1
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "asymmetric elevation is rejected")
	assert_true(_has_error(result, "Elevation"), "elevation error is clear")
	return true


func test_wrong_composition_is_rejected() -> bool:
	var data := _valid_map_data()
	var p1_units := _player_units(data, "player_1")
	p1_units.pop_back()
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "15-piece side is rejected")
	assert_true(_has_error(result, "16"), "composition error is clear")
	return true


func test_duplicate_starting_tile_is_rejected() -> bool:
	var data := _valid_map_data()
	var p1_units := _player_units(data, "player_1")
	var first: Dictionary = p1_units[0] as Dictionary
	var second: Dictionary = p1_units[1] as Dictionary
	second["tile"] = (first["tile"] as Array).duplicate()
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "duplicate starting tile is rejected")
	assert_true(_has_error(result, "share tile"), "duplicate error is clear")
	return true


func test_non_playable_starting_tile_is_rejected() -> bool:
	var data := _valid_map_data()
	var p1_units := _player_units(data, "player_1")
	var unit: Dictionary = p1_units[0] as Dictionary
	unit["tile"] = [0, 0]
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "void starting tile is rejected")
	assert_true(_has_error(result, "not playable"), "playability error is clear")
	return true


func test_starting_tile_outside_home_half_is_rejected() -> bool:
	var data := _valid_map_data()
	var p1_units := _player_units(data, "player_1")
	var unit: Dictionary = p1_units[0] as Dictionary
	unit["tile"] = [8, 7]
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "starting tile outside home half is rejected")
	assert_true(_has_error(result, "home half"), "home-half error is clear")
	return true


func test_deployment_mismatch_is_rejected() -> bool:
	var data := _valid_map_data()
	var deployment: Dictionary = data["deployment"] as Dictionary
	var p1_tiles: Array = deployment["player_1"] as Array
	p1_tiles.pop_back()
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "incomplete deployment is rejected")
	assert_true(_has_error(result, "Deployment area"), "deployment error is clear")
	return true


func test_asymmetric_gold_mine_is_rejected() -> bool:
	var data := _valid_map_data()
	data["gold_mines"] = [{"tile": [8, 8]}]
	var result := MapIO.load_from_text(_map_text(data))
	assert_false(result.is_valid(), "unpaired gold mine is rejected")
	assert_true(_has_error(result, "point-symmetric"), "mine symmetry error is clear")
	return true


func test_symmetric_gold_mines_are_accepted() -> bool:
	var data := _valid_map_data()
	data["gold_mines"] = [{"tile": [8, 8]}, {"tile": [7, 7]}]
	var result := MapIO.load_from_text(_map_text(data))
	assert_true(result.is_valid(), "symmetric mines are accepted: %s" % str(result.errors))
	if result.is_valid():
		assert_eq(result.map.gold_mines.size(), 2, "mines are preserved")
	return true


func test_first_turn_capture_is_rejected() -> bool:
	var result := MapIO.load_from_file(STANDARD_MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var map := result.map
	assert_true(
		_move_starting_unit(map, GameConfig.Player.PLAYER_1, UnitType.Type.ROOK, Vector2i(4, 15), Vector2i(8, 8)),
		"moved player 1 rook"
	)
	assert_true(
		_move_starting_unit(map, GameConfig.Player.PLAYER_2, UnitType.Type.ROOK, Vector2i(11, 0), Vector2i(7, 7)),
		"moved player 2 rook"
	)
	assert_true(
		_move_starting_unit(map, GameConfig.Player.PLAYER_1, UnitType.Type.PAWN, Vector2i(4, 14), Vector2i(7, 8)),
		"moved player 1 pawn"
	)
	assert_true(
		_move_starting_unit(map, GameConfig.Player.PLAYER_2, UnitType.Type.PAWN, Vector2i(11, 1), Vector2i(8, 7)),
		"moved player 2 pawn"
	)
	var errors := MapValidator.validate(map)
	assert_true(not errors.is_empty(), "first-turn capture is rejected")
	assert_true(_errors_contain(errors, "First-turn capture"), "first-turn capture error is clear")
	return true


func _valid_map_data() -> Dictionary:
	var text := FileAccess.get_file_as_string(STANDARD_MAP_PATH)
	return JSON.parse_string(text) as Dictionary


func _map_text(data: Dictionary) -> String:
	return JSON.stringify(data, "  ", true) + "\n"


func _player_units(data: Dictionary, player_key: String) -> Array:
	var starting: Dictionary = data["starting_units"] as Dictionary
	return starting[player_key] as Array


func _has_error(result: MapLoadResult, needle: String) -> bool:
	for error: String in result.errors:
		if error.contains(needle):
			return true
	return false


func _move_starting_unit(
	map: MapData,
	player: int,
	unit_type: int,
	from_tile: Vector2i,
	to_tile: Vector2i
) -> bool:
	var units := map.get_starting_units(player)
	for unit: MapStartingUnit in units:
		if unit.type == unit_type and unit.tile == from_tile:
			unit.tile = to_tile
			map.set_starting_units(player, units)
			return true
	return false


func _errors_contain(errors: Array[String], needle: String) -> bool:
	for error: String in errors:
		if error.contains(needle):
			return true
	return false
