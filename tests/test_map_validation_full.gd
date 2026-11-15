extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const STANDARD_MAP_PATH: String = "res://maps/standard_template.json"
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"


func test_terrain_showcase_passes_full_validation() -> bool:
	var map := _load_map(TERRAIN_MAP_PATH)
	assert_not_null(map, "terrain map loads")
	if map == null:
		return true
	var errors := MapValidator.validate_for_match(map)
	assert_true(errors.is_empty(), "terrain showcase passes full validation: %s" % str(errors))
	assert_true(MapValidator.validate_issues(map, true).is_empty(), "no structured issues")
	return true


func test_fixture_without_mines_fails_full_validation_but_still_loads() -> bool:
	var result := MapIO.load_from_file(STANDARD_MAP_PATH)
	assert_true(result.is_valid(), "standard fixture still loads through MapIO")
	if not result.is_valid():
		return true
	var basic := MapValidator.validate(result.map)
	assert_true(basic.is_empty(), "basic validation still accepts the fixture")
	var full := MapValidator.validate_for_match(result.map)
	assert_false(full.is_empty(), "full validation rejects a mine-free fixture")
	assert_true(_messages_contain(full, "shared gold mines"), "shared-mine error is clear")
	return true


func test_island_mines_are_allowed_but_not_counted() -> bool:
	var map := _load_map(TERRAIN_MAP_PATH)
	assert_not_null(map, "terrain map loads")
	if map == null:
		return true
	var island := Vector2i(0, 8)
	var island_mirror := GameConfig.mirror_tile(island)
	for neighbor: Vector2i in [
		Vector2i(0, 7),
		Vector2i(1, 7),
		Vector2i(1, 8),
		Vector2i(1, 9),
		Vector2i(0, 9),
	]:
		_paint_water(map, neighbor)
	map.gold_mines.append(island)
	map.gold_mines.append(island_mirror)

	var basic := MapValidator.validate(map)
	assert_true(basic.is_empty(), "island mines are structurally valid: %s" % str(basic))
	var full := MapValidator.validate_for_match(map)
	assert_true(
		full.is_empty(),
		"island mines are allowed alongside two shared mines: %s" % str(full)
	)

	var island_only: Array[Vector2i] = []
	for mine_tile: Vector2i in map.gold_mines:
		if mine_tile != Vector2i(5, 6) and mine_tile != Vector2i(10, 9):
			island_only.append(mine_tile)
	map.gold_mines = island_only
	basic = MapValidator.validate(map)
	assert_true(basic.is_empty(), "island-only map is structurally valid: %s" % str(basic))
	full = MapValidator.validate_for_match(map)
	assert_false(full.is_empty(), "island-only mines do not satisfy the shared minimum")
	assert_true(_messages_contain(full, "shared gold mines"), "shared-mine error is clear")
	var full_issues := MapValidator.validate_issues(map, true)
	var issue := _issue_containing(full_issues, "shared gold mines")
	assert_not_null(issue, "shared-mine issue is structured")
	if issue != null:
		assert_true(issue.tiles.has(island), "island mine is listed as affected")
		assert_true(issue.tiles.has(island_mirror), "mirrored island mine is listed")
	return true


func test_trapped_deployment_fails_full_validation() -> bool:
	var map := _load_map(TERRAIN_MAP_PATH)
	assert_not_null(map, "terrain map loads")
	if map == null:
		return true
	for column in range(2, 14):
		_paint_water(map, Vector2i(column, 13))
		_paint_water(map, Vector2i(column, 2))
	_paint_water(map, Vector2i(1, 12))
	_paint_water(map, Vector2i(14, 12))

	var basic := MapValidator.validate(map)
	assert_true(basic.is_empty(), "trapped map is structurally valid: %s" % str(basic))
	var full := MapValidator.validate_for_match(map)
	assert_false(full.is_empty(), "trapped deployment fails full validation")
	assert_true(_messages_contain(full, "shared gold mines"), "mines are unreachable")
	assert_true(_messages_contain(full, "central battlefield"), "central reachability error is clear")
	return true


func test_validation_issues_expose_affected_tiles() -> bool:
	var map := _load_map(STANDARD_MAP_PATH)
	assert_not_null(map, "standard map loads")
	if map == null:
		return true
	var tile := Vector2i(8, 8)
	var mirror := GameConfig.mirror_tile(tile)
	map.board.get_tile(tile).terrain = TerrainType.Type.FOREST
	var issues := MapValidator.validate_issues(map, false)
	assert_eq(issues.size(), 1, "one terrain issue")
	if issues.is_empty():
		return true
	var issue := issues[0]
	assert_true(issue.message.contains("Terrain at"), "terrain message is preserved")
	assert_true(issue.tiles.has(tile), "painted tile is listed")
	assert_true(issue.tiles.has(mirror), "mirror tile is listed")
	var messages := MapValidator.validate(map)
	assert_eq(messages.size(), issues.size(), "string projection matches issue count")
	assert_eq(messages[0], issue.message, "string projection matches the message")
	return true


func test_first_turn_capture_issue_exposes_tiles() -> bool:
	var map := _load_map(STANDARD_MAP_PATH)
	assert_not_null(map, "standard map loads")
	if map == null:
		return true
	_move_unit(map, PLAYER_1, UnitType.Type.PAWN, Vector2i(4, 14), Vector2i(8, 8))
	_move_unit(map, PLAYER_2, UnitType.Type.PAWN, Vector2i(11, 1), Vector2i(7, 7))
	var issues := MapValidator.validate_issues(map, false)
	var issue := _issue_containing(issues, "First-turn capture")
	assert_not_null(issue, "first-turn capture is reported")
	if issue != null:
		assert_eq(issue.tiles.size(), 2, "mover and target tiles are reported")
		assert_true(issue.tiles.has(Vector2i(8, 8)), "mover tile is reported")
		assert_true(issue.tiles.has(Vector2i(7, 7)), "target tile is reported")
	return true


func test_full_validation_preserves_basic_messages() -> bool:
	var map := _load_map(STANDARD_MAP_PATH)
	assert_not_null(map, "standard map loads")
	if map == null:
		return true
	map.board.get_tile(Vector2i(8, 8)).terrain = TerrainType.Type.FOREST
	var basic := MapValidator.validate(map)
	var full := MapValidator.validate_for_match(map)
	assert_eq(full, basic, "full validation reuses basic messages")
	return true


func _load_map(path: String) -> MapData:
	var result := MapIO.load_from_file(path)
	if not result.is_valid():
		push_error("Could not load validation map %s: %s" % [path, str(result.errors)])
		return null
	return result.map


func _paint_water(map: MapData, tile: Vector2i) -> void:
	var mirror := GameConfig.mirror_tile(tile)
	for target: Vector2i in [tile, mirror]:
		var data := map.board.get_tile(target)
		if data != null:
			data.terrain = TerrainType.Type.WATER


func _move_unit(
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


func _messages_contain(messages: Array[String], needle: String) -> bool:
	for message: String in messages:
		if message.contains(needle):
			return true
	return false


func _issue_containing(
	issues: Array[MapValidationIssue],
	needle: String
) -> MapValidationIssue:
	for issue: MapValidationIssue in issues:
		if issue.message.contains(needle):
			return issue
	return null
