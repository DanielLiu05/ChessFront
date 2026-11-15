extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const STANDARD_MAP_PATH: String = "res://maps/standard_template.json"
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"


func test_fog_states_and_hidden_piece_visibility() -> bool:
	var result := MapIO.load_from_file(STANDARD_MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	var observer := MovementTestUtils.add_unit(
		state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 8)
	)
	state.board.get_tile(Vector2i(8, 5)).terrain = TerrainType.Type.FOREST
	var hidden := MovementTestUtils.add_unit(
		state, UnitType.Type.QUEEN, PLAYER_2, Vector2i(8, 5)
	)
	MovementTestUtils.reset_knowledge(state)
	var knowledge := state.get_knowledge(PLAYER_1)
	knowledge.mark_visible(Vector2i(3, 3))
	knowledge.visible.erase(Vector2i(3, 3))
	var view := PlayerView.for_player(state, PLAYER_1)
	var board := _board_view()
	board.build(state.board)
	board.update_from_view(view, [], [])

	assert_not_null(board.get_piece_view(observer.id), "friendly piece is rendered")
	assert_null(board.get_piece_view(hidden.id), "concealed enemy has no piece view")
	var visible_tile := board.get_tile_view(Vector2i(8, 8))
	assert_eq(visible_tile.get_fog_state(), TileView.FogState.VISIBLE, "visible tile")
	assert_true(visible_tile.is_terrain_visible(), "visible terrain is shown")
	assert_false(visible_tile.is_fog_overlay_visible(), "no overlay on visible tile")
	var explored_tile := board.get_tile_view(Vector2i(3, 3))
	assert_eq(explored_tile.get_fog_state(), TileView.FogState.EXPLORED, "explored tile")
	assert_true(explored_tile.is_terrain_visible(), "explored terrain is shown")
	assert_true(explored_tile.is_fog_overlay_visible(), "explored tile has fog overlay")
	var unexplored_tile := board.get_tile_view(Vector2i(0, 8))
	assert_eq(
		unexplored_tile.get_fog_state(), TileView.FogState.UNEXPLORED, "unexplored tile"
	)
	assert_false(unexplored_tile.is_terrain_visible(), "unexplored terrain is hidden")
	assert_true(unexplored_tile.is_fog_tile_visible(), "unexplored fog tile is shown")

	knowledge.mark_enemy_detected(hidden.id)
	view = PlayerView.for_player(state, PLAYER_1)
	board.update_from_view(view, [], [])
	assert_not_null(board.get_piece_view(hidden.id), "detected enemy appears")
	knowledge.detected_enemy_ids.clear()
	view = PlayerView.for_player(state, PLAYER_1)
	board.update_from_view(view, [], [])
	assert_null(board.get_piece_view(hidden.id), "hidden enemy disappears")
	board.free()
	return true


func test_highlights_follow_player_knowledge() -> bool:
	var state := _standard_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var model := PresentationModel.new(state, PLAYER_1)
	var board := _board_view()
	board.build(state.board)
	board.update_from_view(model.view, [], [])
	model.click_tile(Vector2i(4, 14))
	board.set_highlights(
		model.selected_tile,
		model.legal_destinations,
		model.capture_destinations,
		model.bridge_build_targets,
		model.bridge_destroy_targets,
		model.recruitment_spawn_tiles
	)
	assert_true(board.has_highlight(Vector2i(4, 14)), "selected tile is highlighted")
	assert_true(board.has_highlight(Vector2i(4, 13)), "legal destination is highlighted")
	assert_false(board.has_highlight(Vector2i(4, 1)), "concealed enemy tile is not highlighted")
	board.free()
	return true


func test_mine_and_token_visibility() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(result.map)
	var mine_a := state.get_gold_mine_at(Vector2i(5, 6))
	var mine_b := state.get_gold_mine_at(Vector2i(10, 9))
	assert_not_null(mine_a, "mine A exists")
	assert_not_null(mine_b, "mine B exists")
	if mine_a == null or mine_b == null:
		return true
	mine_a.gold_available = true
	mine_b.gold_available = true
	var knowledge := state.get_knowledge(PLAYER_1)
	knowledge.mark_visible(Vector2i(5, 6))
	knowledge.mark_visible(Vector2i(10, 9))
	knowledge.visible.erase(Vector2i(10, 9))
	var view := PlayerView.for_player(state, PLAYER_1)
	var board := _board_view()
	board.build(state.board)
	board.update_from_view(
		view,
		[Vector2i(5, 6), Vector2i(10, 9)],
		[Vector2i(5, 6), Vector2i(10, 9)]
	)
	var tile_a := board.get_tile_view(Vector2i(5, 6))
	var tile_b := board.get_tile_view(Vector2i(10, 9))
	assert_true(tile_a.is_mine_visible(), "visible mine marker")
	assert_true(tile_a.is_token_visible(), "visible token marker")
	assert_true(tile_b.is_mine_visible(), "explored mine marker")
	assert_false(tile_b.is_token_visible(), "hidden token marker")
	board.free()
	return true


func test_terrain_decorations_and_markers() -> bool:
	var packed := load("res://scenes/board/Tile.tscn") as PackedScene
	assert_not_null(packed, "tile scene loads")
	if packed == null:
		return true
	var forest := packed.instantiate() as TileView
	forest.setup(Vector2i(4, 4), TerrainType.Type.FOREST, Vector3.ZERO)
	var forest_decorations := forest.get_node_or_null("Decorations")
	assert_not_null(forest_decorations, "forest decorations exist")
	if forest_decorations != null:
		assert_true(forest_decorations.get_child_count() > 0, "forest has trees")
	forest.free()

	var hill := packed.instantiate() as TileView
	hill.setup(Vector2i(4, 4), TerrainType.Type.HILL, Vector3.ZERO)
	var hill_decorations := hill.get_node_or_null("Decorations")
	assert_not_null(hill_decorations, "hill decorations exist")
	if hill_decorations != null:
		assert_true(hill_decorations.get_child_count() > 0, "hill has rocks")
	assert_true(
		hill.surface_height() > TileView.height_for_terrain(TerrainType.Type.GROUND),
		"hill is taller than ground"
	)
	hill.free()

	var water := packed.instantiate() as TileView
	water.setup(Vector2i(5, 7), TerrainType.Type.WATER, Vector3.ZERO)
	water.set_view(
		TerrainType.Type.WATER,
		true,
		TileView.FogState.VISIBLE,
		true,
		true
	)
	assert_true(water.is_bridge_visible(), "bridge marker is visible")
	assert_true(water.is_mine_visible(), "mine marker is visible")
	assert_true(water.is_token_visible(), "token marker is visible")
	water.free()
	return true


func test_all_piece_types_build_with_pick_metadata() -> bool:
	var packed := load("res://scenes/pieces/Piece.tscn") as PackedScene
	assert_not_null(packed, "piece scene loads")
	if packed == null:
		return true
	var types := UnitRegistry.get_all_types()
	var letters: Array[String] = ["K", "Q", "R", "B", "N", "P", "S", "E"]
	for index in types.size():
		var piece := packed.instantiate() as PieceView
		assert_not_null(piece, "piece instantiates")
		if piece == null:
			continue
		piece.setup(
			index + 1,
			types[index],
			PLAYER_1,
			Vector2i(8, 8),
			Vector3.ZERO
		)
		assert_eq(piece.letter(), letters[index], "letter for type %d" % types[index])
		var body := piece.get_node_or_null("PickBody") as StaticBody3D
		assert_not_null(body, "piece collider exists")
		if body != null:
			assert_eq(body.get_meta("tile"), Vector2i(8, 8), "piece collider metadata")
		assert_true(piece.get_child_count() >= 2, "piece has visuals and collider")
		piece.free()
	return true


func _board_view() -> BoardView:
	var packed := load("res://scenes/board/Board.tscn") as PackedScene
	var view := packed.instantiate() as BoardView
	assert_not_null(view, "board scene instantiates")
	return view


func _standard_state() -> GameState:
	var result := MapIO.load_from_file(STANDARD_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load standard map: %s" % str(result.errors))
		return null
	return GameState.new(result.map)
