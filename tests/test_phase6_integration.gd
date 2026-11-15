extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const STANDARD_MAP_PATH: String = "res://maps/standard_template.json"


func test_model_move_updates_board_view() -> bool:
	var loaded := MapLibrary.load_by_id("borderlands")
	assert_true(loaded.is_valid(), "borderlands loads")
	if not loaded.is_valid():
		return true
	var state := GameState.new(loaded.map)
	var model := PresentationModel.new(state, PLAYER_1)
	var board := _board_view()
	board.build(state.board)
	board.update_from_view(
		model.view, model.explored_mine_tiles(), model.visible_gold_token_tiles()
	)
	var pawn := state.get_unit_at(Vector2i(4, 14))
	assert_not_null(pawn, "pawn exists")
	if pawn == null:
		board.free()
		return true
	model.click_tile(Vector2i(4, 14))
	board.set_highlights(
		model.selected_tile,
		model.legal_destinations,
		model.capture_destinations,
		model.bridge_build_targets,
		model.bridge_destroy_targets,
		model.recruitment_spawn_tiles
	)
	assert_true(board.has_highlight(Vector2i(4, 13)), "destination is highlighted")
	model.click_tile(Vector2i(4, 13))
	board.update_from_view(
		model.view, model.explored_mine_tiles(), model.visible_gold_token_tiles()
	)
	board.set_highlights(
		model.selected_tile,
		model.legal_destinations,
		model.capture_destinations,
		model.bridge_build_targets,
		model.bridge_destroy_targets,
		model.recruitment_spawn_tiles
	)
	assert_eq(state.ply, 1, "move consumes one ply")
	assert_eq(state.active_player, PLAYER_2, "turn advances")
	assert_eq(pawn.tile, Vector2i(4, 13), "pawn moved")
	var piece := board.get_piece_view(pawn.id)
	assert_not_null(piece, "piece view exists")
	if piece != null:
		assert_eq(piece.tile, Vector2i(4, 13), "piece view follows the move")
	assert_false(board.has_highlight(Vector2i(4, 13)), "highlights clear after the action")
	board.free()
	return true


func test_scout_move_reveals_fog() -> bool:
	var loaded := MapIO.load_from_file(STANDARD_MAP_PATH)
	assert_true(loaded.is_valid(), "standard map loads")
	if not loaded.is_valid():
		return true
	var state := GameState.new(loaded.map)
	MovementTestUtils.clear_units(state)
	var scout := MovementTestUtils.add_unit(
		state, UnitType.Type.SCOUT, PLAYER_1, Vector2i(8, 8)
	)
	MovementTestUtils.reset_knowledge(state)
	var model := PresentationModel.new(state, PLAYER_1)
	var board := _board_view()
	board.build(state.board)
	board.update_from_view(model.view, [], [])
	var before := board.get_tile_view(Vector2i(8, 2))
	assert_eq(before.get_fog_state(), TileView.FogState.UNEXPLORED, "far tile starts hidden")
	model.click_tile(Vector2i(8, 8))
	var move := model.move_selected_to(Vector2i(8, 5))
	assert_true(move.success, "scout move succeeds")
	board.update_from_view(
		model.view, model.explored_mine_tiles(), model.visible_gold_token_tiles()
	)
	var after := board.get_tile_view(Vector2i(8, 2))
	assert_eq(after.get_fog_state(), TileView.FogState.VISIBLE, "scout reveals the far tile")
	assert_true(after.is_terrain_visible(), "revealed terrain is visible")
	var piece := board.get_piece_view(scout.id)
	assert_not_null(piece, "scout piece view exists")
	if piece != null:
		assert_eq(piece.tile, Vector2i(8, 5), "scout piece view follows the move")
	board.free()
	return true


func _board_view() -> BoardView:
	var packed := load("res://scenes/board/Board.tscn") as PackedScene
	var view := packed.instantiate() as BoardView
	assert_not_null(view, "board scene instantiates")
	return view
