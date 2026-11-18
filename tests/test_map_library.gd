extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const STANDARD_MAP_PATH: String = "res://maps/standard_template.json"
const TEMP_DIRECTORY: String = "user://chessfront_test_library"


func test_library_contains_validated_maps() -> bool:
	assert_eq(GameConfig.MAP_LIBRARY_DIRECTORY, "res://maps/library", "library directory")
	var paths := MapLibrary.list_paths()
	assert_true(paths.size() >= 3, "library has at least three maps")
	var results := MapLibrary.load_all()
	assert_eq(results.size(), paths.size(), "every path is loaded")
	var ids: Dictionary[String, bool] = {}
	var exploration := ExplorationProvider.all_explored()
	for result: MapLoadResult in results:
		assert_true(result.is_valid(), "library map is valid: %s" % str(result.errors))
		if not result.is_valid():
			continue
		var map := result.map
		assert_false(ids.has(map.id), "map id is unique: %s" % map.id)
		ids[map.id] = true
		assert_true(map.gold_mines.size() >= 2, "map has at least two mines: %s" % map.id)
		for player: int in [PLAYER_1, PLAYER_2]:
			for unit: MapStartingUnit in map.get_starting_units(player):
				assert_eq(
					map.board.get_tile(unit.tile).terrain,
					TerrainType.Type.GROUND,
					"starting unit is on ground in %s" % map.id
				)
			for tile: Vector2i in map.get_deployment_tiles(player):
				assert_eq(
					map.board.get_tile(tile).terrain,
					TerrainType.Type.GROUND,
					"deployment tile is on ground in %s" % map.id
				)
		var state := GameState.new(map)
		assert_eq(state.get_all_units().size(), 32, "map deploys 32 units: %s" % map.id)
		var has_move := false
		for unit: GameUnit in state.get_units_for_player(PLAYER_1):
			if not MovementRules.legal_destinations(state, unit, exploration).is_empty():
				has_move = true
				break
		assert_true(has_move, "map has a legal action: %s" % map.id)

	for path: String in paths:
		var text := FileAccess.get_file_as_string(path)
		var loaded := MapIO.load_from_file(path)
		assert_true(loaded.is_valid(), "map file loads: %s" % path)
		if loaded.is_valid():
			assert_eq(MapIO.to_json_text(loaded.map), text, "canonical round-trip: %s" % path)

	var errors := MapLibrary.library_errors()
	assert_true(errors.is_empty(), "library has no errors: %s" % str(errors))
	var known := MapLibrary.load_by_id("borderlands")
	assert_true(known.is_valid(), "load_by_id finds a library map")
	if known.is_valid():
		assert_eq(known.map.id, "borderlands", "load_by_id returns the requested map")
	var missing := MapLibrary.load_by_id("missing_map")
	assert_false(missing.is_valid(), "load_by_id rejects an unknown id")
	assert_true(_errors_contain(missing.errors, "not found"), "unknown-id error is clear")
	return true


func test_library_entries_have_names_and_summaries() -> bool:
	var entries := MapLibrary.list_entries()
	assert_true(entries.size() >= 3, "library has the shipped map entries")
	var ids: Dictionary[String, bool] = {}
	for entry: MapEntry in entries:
		assert_false(ids.has(entry.id), "entry id is unique: %s" % entry.id)
		ids[entry.id] = true
		assert_false(entry.display_name().is_empty(), "entry has a display name: %s" % entry.id)
		assert_true(entry.path.begins_with(GameConfig.MAP_LIBRARY_DIRECTORY), "entry path is in the library")
		assert_true(entry.playable_tile_count > 0, "entry has playable tiles: %s" % entry.id)
		assert_true(entry.mine_count >= 2, "entry has at least two mines: %s" % entry.id)
		assert_true(entry.summary_text().contains("tiles"), "summary reports tiles")
		assert_true(entry.summary_text().contains("mines"), "summary reports mines")
	for expected: String in ["borderlands", "highland_woods", "river_crossing"]:
		assert_true(ids.has(expected), "entry is present: %s" % expected)
	return true


func test_library_rejects_invalid_map() -> bool:
	_prepare_temp_directory()
	var source := _load_map(STANDARD_MAP_PATH)
	assert_not_null(source, "source map loads")
	if source == null:
		return true
	var path := TEMP_DIRECTORY.path_join("invalid.json")
	assert_eq(MapIO.save_to_file(source, path), OK, "invalid map saved for the test")
	var result := MapLibrary.load_map(path)
	assert_false(result.is_valid(), "map without shared mines is rejected")
	assert_true(_errors_contain(result.errors, "shared gold mines"), "full-validation error is reported")
	var errors := MapLibrary.library_errors(TEMP_DIRECTORY)
	assert_true(_errors_contain(errors, "shared gold mines"), "library errors include the invalid map")
	assert_eq(
		MapLibrary.list_entries(TEMP_DIRECTORY).size(),
		0,
		"invalid maps are excluded from setup entries"
	)
	_cleanup_temp_directory()
	return true


func test_library_rejects_duplicate_ids() -> bool:
	_prepare_temp_directory()
	var source := _load_map(TERRAIN_MAP_PATH)
	assert_not_null(source, "source map loads")
	if source == null:
		return true
	var first := source.duplicate_map()
	first.id = "duplicate_map"
	var second := source.duplicate_map()
	second.id = "duplicate_map"
	assert_eq(
		MapIO.save_to_file(first, TEMP_DIRECTORY.path_join("a.json")),
		OK,
		"first duplicate saved"
	)
	assert_eq(
		MapIO.save_to_file(second, TEMP_DIRECTORY.path_join("b.json")),
		OK,
		"second duplicate saved"
	)
	var errors := MapLibrary.library_errors(TEMP_DIRECTORY)
	assert_true(_errors_contain(errors, "Duplicate map id"), "duplicate ids are reported")
	var result := MapLibrary.load_by_id("duplicate_map", TEMP_DIRECTORY)
	assert_false(result.is_valid(), "duplicate id cannot be selected")
	assert_true(_errors_contain(result.errors, "duplicated"), "duplicate selection error is clear")
	assert_eq(
		MapLibrary.list_entries(TEMP_DIRECTORY).size(),
		0,
		"duplicate ids are excluded from setup entries"
	)
	_cleanup_temp_directory()
	return true


func _load_map(path: String) -> MapData:
	var result := MapIO.load_from_file(path)
	if not result.is_valid():
		push_error("Could not load test map %s: %s" % [path, str(result.errors)])
		return null
	return result.map


func _prepare_temp_directory() -> void:
	_cleanup_temp_directory()
	DirAccess.make_dir_recursive_absolute(TEMP_DIRECTORY)


func _cleanup_temp_directory() -> void:
	var access := DirAccess.open(TEMP_DIRECTORY)
	if access == null:
		return
	for file_name: String in access.get_files():
		DirAccess.remove_absolute(TEMP_DIRECTORY.path_join(file_name))


func _errors_contain(errors: Array[String], needle: String) -> bool:
	for message: String in errors:
		if message.contains(needle):
			return true
	return false
