extends TestCase

var board: BoardData


func setup_board() -> void:
	board = BoardData.create_standard()


func test_standard_mask_has_216_tiles() -> bool:
	setup_board()
	assert_eq(board.playable_count(), 216, "standard mask tile count")
	assert_true(board.is_point_symmetric_geometry(), "standard mask is point-symmetric")
	return true


func test_row_widths_match_standard() -> bool:
	setup_board()
	for row in GameConfig.BOARD_HEIGHT:
		var count := 0
		for column in GameConfig.BOARD_WIDTH:
			if board.is_playable(Vector2i(column, row)):
				count += 1
		assert_eq(count, GameConfig.STANDARD_ROW_WIDTHS[row], "row %d width" % row)
	return true


func test_bounds_and_playability() -> bool:
	setup_board()
	assert_true(board.is_in_bounds(Vector2i(0, 0)), "(0, 0) is in bounds")
	assert_false(board.is_in_bounds(Vector2i(-1, 0)), "negative x is out of bounds")
	assert_false(board.is_in_bounds(Vector2i(16, 0)), "x == width is out of bounds")
	assert_false(board.is_playable(Vector2i(0, 0)), "corner void is not playable")
	assert_true(board.is_playable(Vector2i(4, 0)), "(4, 0) is playable")
	assert_true(board.is_playable(Vector2i(3, 1)), "(3, 1) is playable")
	assert_true(board.is_playable(Vector2i(15, 7)), "(15, 7) is playable")
	assert_false(board.is_playable(Vector2i(15, 0)), "(15, 0) is void")
	assert_true(board.is_passable(Vector2i(4, 0)), "playable ground is passable")
	assert_false(board.is_passable(Vector2i(0, 0)), "void is not passable")
	return true


func test_tile_defaults() -> bool:
	setup_board()
	var tile := board.get_tile(Vector2i(8, 8))
	assert_not_null(tile, "tile exists")
	assert_eq(tile.coord, Vector2i(8, 8), "tile coordinate")
	assert_eq(tile.terrain, TerrainType.Type.GROUND, "default terrain")
	assert_eq(tile.elevation, 0, "default elevation")
	assert_false(tile.has_bridge, "no bridge by default")
	assert_eq(tile.occupant_id, BoardTileData.NO_OCCUPANT, "no occupant by default")
	assert_false(tile.is_occupied(), "tile starts unoccupied")
	assert_false(tile.ground_gold, "no ground gold by default")
	assert_null(board.get_tile(Vector2i(0, 0)), "void has no tile")
	return true


func test_neighbors_at_irregular_edges() -> bool:
	setup_board()
	assert_eq(board.get_neighbors(Vector2i(8, 8)).size(), 8, "center has eight neighbors")
	assert_eq(board.get_neighbors(Vector2i(4, 0)).size(), 4, "narrow corner has four neighbors")
	assert_eq(board.get_neighbors(Vector2i(14, 3)).size(), 5, "sloped edge has five neighbors")
	assert_eq(board.get_neighbors(Vector2i(3, 0)).size(), 3, "void tile exposes adjacent playable tiles")
	assert_eq(board.get_neighbors(Vector2i(-1, -1)).size(), 0, "far outside has no neighbors")
	return true


func test_neighbor_contents_are_playable() -> bool:
	setup_board()
	for neighbor: Vector2i in board.get_neighbors(Vector2i(4, 0)):
		assert_true(board.is_playable(neighbor), "neighbor %s is playable" % str(neighbor))
	return true


func test_terrain_passability_and_bridges() -> bool:
	setup_board()
	var coord := Vector2i(8, 8)
	var tile := board.get_tile(coord)
	assert_true(board.is_passable(coord), "ground is passable")
	tile.terrain = TerrainType.Type.FOREST
	assert_true(board.is_passable(coord), "forest is passable")
	tile.terrain = TerrainType.Type.HILL
	assert_true(board.is_passable(coord), "hill is passable")
	tile.terrain = TerrainType.Type.WATER
	assert_false(board.is_passable(coord), "unbridged water is blocked")
	tile.has_bridge = true
	assert_true(board.is_passable(coord), "bridged water is passable")
	tile.has_bridge = false
	assert_false(board.is_passable(coord), "removing the bridge blocks water again")
	tile.terrain = TerrainType.Type.GROUND
	tile.has_bridge = true
	assert_true(board.is_passable(coord), "a bridge on ground does not block")
	return true
