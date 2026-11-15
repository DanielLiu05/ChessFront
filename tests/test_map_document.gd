extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"


func test_new_document_contents() -> bool:
	var document := MapDocument.create_new("test_map", "Test Map")
	assert_not_null(document, "document created")
	if document == null:
		return true
	assert_eq(document.map.id, "test_map", "map id")
	assert_eq(document.map.name, "Test Map", "map name")
	assert_eq(document.map.board.playable_count(), 216, "standard mask")
	assert_eq(document.map.get_deployment_tiles(PLAYER_1).size(), 18, "player 1 deployment")
	assert_eq(document.map.get_deployment_tiles(PLAYER_2).size(), 18, "player 2 deployment")
	assert_eq(document.map.get_starting_units(PLAYER_1).size(), 16, "player 1 units")
	assert_eq(document.map.get_starting_units(PLAYER_2).size(), 16, "player 2 units")
	assert_true(document.map.gold_mines.is_empty(), "new map has no mines")
	assert_false(document.dirty, "new document is clean")
	var basic := MapValidator.validate(document.map)
	assert_true(basic.is_empty(), "new map is structurally valid: %s" % str(basic))
	var composition := document.get_composition(PLAYER_1)
	assert_eq(int(composition.get(UnitType.Type.KING, 0)), 1, "one king")
	assert_eq(int(composition.get(UnitType.Type.QUEEN, 0)), 1, "one queen")
	assert_eq(int(composition.get(UnitType.Type.ROOK, 0)), 2, "two rooks")
	assert_eq(int(composition.get(UnitType.Type.BISHOP, 0)), 2, "two bishops")
	assert_eq(int(composition.get(UnitType.Type.KNIGHT, 0)), 2, "two knights")
	assert_eq(int(composition.get(UnitType.Type.PAWN, 0)), 8, "eight pawns")
	var p1_king := document.get_starting_unit_at(Vector2i(8, 15))
	assert_not_null(p1_king, "player 1 king exists")
	if p1_king != null:
		assert_eq(p1_king.type, UnitType.Type.KING, "player 1 king type")
	var p2_king := document.get_starting_unit_at(Vector2i(7, 0))
	assert_not_null(p2_king, "player 2 king exists")
	if p2_king != null:
		assert_eq(p2_king.type, UnitType.Type.KING, "player 2 king type")
	var full := document.validate()
	assert_false(full.is_empty(), "new map needs mines before export")
	assert_true(_issues_contain(full, "shared gold mines"), "missing-mine issue is reported")
	return true


func test_terrain_edits_mirror() -> bool:
	var document := MapDocument.create_new()
	var tile := Vector2i(3, 6)
	var mirror := GameConfig.mirror_tile(tile)
	assert_true(document.paint_terrain(tile, TerrainType.Type.FOREST), "terrain paint succeeds")
	assert_eq(document.get_terrain(tile), TerrainType.Type.FOREST, "painted tile")
	assert_eq(document.get_terrain(mirror), TerrainType.Type.FOREST, "mirror painted")
	assert_true(document.dirty, "edit marks the document dirty")
	assert_false(
		document.paint_terrain(Vector2i(0, 0), TerrainType.Type.FOREST),
		"void tile is rejected"
	)
	assert_false(document.paint_terrain(Vector2i(8, 8), 999), "unknown terrain is rejected")
	return true


func test_mine_toggle_mirrors() -> bool:
	var document := MapDocument.create_new()
	var tile := Vector2i(5, 6)
	var mirror := GameConfig.mirror_tile(tile)
	assert_true(document.toggle_mine(tile), "mine added")
	assert_true(document.has_mine(tile), "mine on the tile")
	assert_true(document.has_mine(mirror), "mine on the mirror")
	assert_eq(document.map.gold_mines.size(), 2, "two mirrored mines")
	assert_true(document.toggle_mine(tile), "mine removed")
	assert_false(document.has_mine(tile), "tile is clear")
	assert_false(document.has_mine(mirror), "mirror is clear")
	assert_true(document.map.gold_mines.is_empty(), "no mines remain")
	assert_false(document.toggle_mine(Vector2i(0, 0)), "void tile is rejected")
	document.paint_terrain(Vector2i(8, 8), TerrainType.Type.WATER)
	assert_false(document.toggle_mine(Vector2i(8, 8)), "water mine is rejected")
	return true


func test_unit_placement_and_removal_mirror() -> bool:
	var document := MapDocument.create_new()
	var p1_king_tile := Vector2i(8, 15)
	var p2_king_tile := Vector2i(7, 0)
	assert_true(document.remove_starting_unit(p1_king_tile), "king removed")
	assert_null(document.get_starting_unit_at(p1_king_tile), "player 1 king is gone")
	assert_null(document.get_starting_unit_at(p2_king_tile), "player 2 king is gone")
	assert_true(
		document.place_starting_unit(PLAYER_1, UnitType.Type.KING, p1_king_tile),
		"king placed"
	)
	var placed_p1 := document.get_starting_unit_at(p1_king_tile)
	var placed_p2 := document.get_starting_unit_at(p2_king_tile)
	assert_not_null(placed_p1, "player 1 king is back")
	assert_not_null(placed_p2, "player 2 king is back")
	if placed_p1 != null:
		assert_eq(placed_p1.type, UnitType.Type.KING, "player 1 king type")
	if placed_p2 != null:
		assert_eq(placed_p2.type, UnitType.Type.KING, "player 2 king type")

	assert_true(
		document.place_starting_unit(PLAYER_1, UnitType.Type.ROOK, p1_king_tile),
		"rook replaces the king pair"
	)
	var replaced_p1 := document.get_starting_unit_at(p1_king_tile)
	var replaced_p2 := document.get_starting_unit_at(p2_king_tile)
	if replaced_p1 != null:
		assert_eq(replaced_p1.type, UnitType.Type.ROOK, "player 1 replacement type")
	if replaced_p2 != null:
		assert_eq(replaced_p2.type, UnitType.Type.ROOK, "player 2 replacement type")
	var composition := document.get_composition(PLAYER_1)
	assert_eq(int(composition.get(UnitType.Type.KING, 0)), 0, "king was replaced")
	assert_eq(int(composition.get(UnitType.Type.ROOK, 0)), 3, "third rook added")

	assert_false(
		document.place_starting_unit(PLAYER_1, UnitType.Type.SCOUT, Vector2i(6, 13)),
		"Scout is not a starting type"
	)
	assert_false(
		document.place_starting_unit(PLAYER_1, UnitType.Type.PAWN, Vector2i(8, 7)),
		"tile outside the player home half is rejected"
	)
	assert_false(
		document.place_starting_unit(PLAYER_1, UnitType.Type.PAWN, Vector2i(0, 0)),
		"void tile is rejected"
	)
	document.paint_terrain(Vector2i(8, 13), TerrainType.Type.WATER)
	assert_false(
		document.place_starting_unit(PLAYER_1, UnitType.Type.PAWN, Vector2i(8, 13)),
		"water tile is rejected"
	)
	return true


func test_from_map_copies_deeply() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "source map loads")
	if not result.is_valid():
		return true
	var source := result.map
	var before := MapIO.to_json_text(source)
	var document := MapDocument.from_map(source, TERRAIN_MAP_PATH)
	assert_not_null(document, "document created from map")
	if document == null:
		return true
	assert_eq(MapIO.to_json_text(document.map), before, "copy matches the source")
	assert_eq(document.source_path, TERRAIN_MAP_PATH, "source path is recorded")
	assert_false(document.dirty, "loaded document is clean")
	assert_true(document.paint_terrain(Vector2i(3, 6), TerrainType.Type.HILL), "copy edited")
	assert_eq(MapIO.to_json_text(source), before, "source map is unchanged")
	assert_ne(MapIO.to_json_text(document.map), before, "copy is modified")
	return true


func test_new_document_with_two_mines_is_exportable() -> bool:
	var document := MapDocument.create_new("exportable", "Exportable")
	assert_true(document.toggle_mine(Vector2i(5, 6)), "mine pair added")
	var issues := document.validate()
	assert_true(
		issues.is_empty(),
		"standard map with one mine pair passes full validation: %s"
		% _issue_messages(issues)
	)
	assert_true(document.is_exportable(), "document is exportable")
	return true


func test_edit_resynchronizes_the_clicked_pair_in_a_draft() -> bool:
	var document := MapDocument.create_new()
	var p2_units := document.map.get_starting_units(PLAYER_2)
	for unit: MapStartingUnit in p2_units:
		if unit.type == UnitType.Type.KING:
			unit.tile = Vector2i(6, 0)
	document.map.set_starting_units(PLAYER_2, p2_units)
	assert_true(document.remove_starting_unit(Vector2i(6, 0)), "asymmetric unit removed")
	assert_null(document.get_starting_unit_at(Vector2i(6, 0)), "asymmetric tile is clear")
	assert_null(document.get_starting_unit_at(Vector2i(9, 15)), "mirror tile is cleared")
	return true


func _issues_contain(issues: Array[MapValidationIssue], needle: String) -> bool:
	for issue: MapValidationIssue in issues:
		if issue.message.contains(needle):
			return true
	return false


func _issue_messages(issues: Array[MapValidationIssue]) -> String:
	var messages: Array[String] = []
	for issue: MapValidationIssue in issues:
		messages.append(issue.message)
	return "; ".join(messages)
