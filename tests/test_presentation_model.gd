extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const STANDARD_MAP_PATH: String = "res://maps/standard_template.json"
const TERRAIN_MAP_PATH: String = "res://maps/terrain_showcase.json"
const MINE_A: Vector2i = Vector2i(5, 6)


func test_selection_and_knowledge_highlights() -> bool:
	var state := _standard_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var model := PresentationModel.new(state, PLAYER_1)
	var pawn := state.get_unit_at(Vector2i(4, 14))
	assert_not_null(pawn, "player 1 pawn")
	if pawn == null:
		return true
	assert_eq(
		model.click_tile(Vector2i(4, 14)),
		PresentationModel.ClickResult.SELECTED,
		"friendly pawn selected"
	)
	assert_eq(model.selected_unit().id, pawn.id, "selected unit id")
	assert_true(model.legal_destinations.has(Vector2i(4, 13)), "forward step highlighted")
	assert_false(model.legal_destinations.has(Vector2i(3, 14)), "sideways step not highlighted")
	assert_eq(
		model.click_tile(Vector2i(4, 1)),
		PresentationModel.ClickResult.DESELECTED,
		"concealed enemy tile only deselects"
	)
	assert_null(model.selected_unit(), "selection cleared")
	return true


func test_move_resolves_and_no_hotseat() -> bool:
	var state := _standard_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var model := PresentationModel.new(state, PLAYER_1)
	model.click_tile(Vector2i(4, 14))
	assert_eq(
		model.click_tile(Vector2i(4, 13)),
		PresentationModel.ClickResult.ACTION_OK,
		"move resolves"
	)
	assert_eq(state.ply, 1, "move consumes one ply")
	assert_eq(state.active_player, PLAYER_2, "turn advances")
	assert_false(model.can_interact(), "local player is inactive")
	assert_null(model.selected_unit(), "selection cleared after action")
	assert_eq(
		model.click_tile(Vector2i(4, 1)),
		PresentationModel.ClickResult.IGNORED,
		"local player cannot act for the opponent"
	)
	assert_true(_log_contains(model, "Move unit"), "move is logged")
	return true


func test_invalid_move_does_not_consume_turn() -> bool:
	var state := _standard_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var model := PresentationModel.new(state, PLAYER_1)
	model.click_tile(Vector2i(4, 14))
	var before := state.snapshot_text()
	var result := model.move_selected_to(Vector2i(3, 14))
	assert_false(result.success, "sideways move rejected")
	assert_eq(state.snapshot_text(), before, "state unchanged")
	assert_eq(state.ply, 0, "turn not consumed")
	return true


func test_promotion_pauses_and_completes() -> bool:
	var state := _promotion_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var pawn := state.get_unit_at(Vector2i(8, 1))
	assert_not_null(pawn, "pawn placed")
	if pawn == null:
		return true
	var model := PresentationModel.new(state, PLAYER_1)
	assert_eq(
		model.click_tile(Vector2i(8, 1)),
		PresentationModel.ClickResult.SELECTED,
		"pawn selected"
	)
	assert_eq(
		model.click_tile(Vector2i(8, 0)),
		PresentationModel.ClickResult.PROMOTION_REQUIRED,
		"promotion pauses the move"
	)
	assert_true(model.has_pending_promotion(), "promotion is pending")
	assert_eq(state.ply, 0, "no turn consumed while pending")
	assert_eq(pawn.tile, Vector2i(8, 1), "pawn has not moved")
	var result := model.complete_promotion(UnitType.Type.KNIGHT)
	assert_true(result.success, "promotion move resolves")
	assert_eq(pawn.type, UnitType.Type.KNIGHT, "promotion choice applied")
	assert_eq(state.ply, 1, "promotion consumes the turn")
	assert_false(model.has_pending_promotion(), "pending promotion cleared")

	var cancel_state := _promotion_state()
	assert_not_null(cancel_state, "cancel state built")
	if cancel_state == null:
		return true
	var cancel_pawn := cancel_state.get_unit_at(Vector2i(8, 1))
	var cancel_model := PresentationModel.new(cancel_state, PLAYER_1)
	cancel_model.click_tile(Vector2i(8, 1))
	cancel_model.click_tile(Vector2i(8, 0))
	cancel_model.cancel_promotion()
	assert_eq(cancel_state.ply, 0, "cancelling consumes no turn")
	assert_eq(cancel_pawn.tile, Vector2i(8, 1), "cancelling leaves the pawn in place")
	assert_false(cancel_model.has_pending_promotion(), "pending promotion cancelled")
	return true


func test_recruitment_uses_known_spawn_tiles() -> bool:
	var state := _standard_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	MovementTestUtils.clear_gold(state)
	state.add_gold(PLAYER_1, 3)
	var model := PresentationModel.new(state, PLAYER_1)
	var options := model.available_recruitment_units()
	assert_true(options.has(UnitType.Type.KNIGHT), "affordable knight is available")
	assert_false(options.has(UnitType.Type.BISHOP), "unaffordable bishop is hidden")
	assert_true(model.begin_recruitment(UnitType.Type.KNIGHT), "recruitment mode starts")
	assert_true(model.recruitment_spawn_tiles.size() > 0, "spawn tiles are known")
	var spawn := model.recruitment_spawn_tiles[0]
	var result := model.recruit_at(spawn)
	assert_true(result.success, "recruitment succeeds")
	assert_eq(state.get_gold(PLAYER_1), 0, "price is deducted")
	assert_not_null(result.recruited_unit, "recruited unit is reported")
	assert_eq(state.active_player, PLAYER_2, "recruitment consumes the turn")
	assert_false(model.can_interact(), "local player is inactive after recruiting")
	return true


func test_bridge_build_and_destroy() -> bool:
	var build_state := _engineer_state(false)
	assert_not_null(build_state, "build state built")
	if build_state == null:
		return true
	var build_model := PresentationModel.new(build_state, PLAYER_1)
	assert_eq(
		build_model.click_tile(Vector2i(4, 7)),
		PresentationModel.ClickResult.SELECTED,
		"engineer selected"
	)
	assert_true(
		build_model.bridge_build_targets.has(Vector2i(5, 7)),
		"water bridge target highlighted"
	)
	assert_true(build_model.begin_bridge_build(), "build mode starts")
	var build_result := build_model.bridge_action_at(Vector2i(5, 7))
	assert_true(build_result.success, "bridge builds")
	assert_true(build_state.board.get_tile(Vector2i(5, 7)).has_bridge, "bridge exists")
	assert_eq(build_state.ply, 1, "bridge build consumes the turn")

	var destroy_state := _engineer_state(true)
	assert_not_null(destroy_state, "destroy state built")
	if destroy_state == null:
		return true
	var destroy_model := PresentationModel.new(destroy_state, PLAYER_1)
	destroy_model.click_tile(Vector2i(4, 7))
	assert_true(
		destroy_model.bridge_destroy_targets.has(Vector2i(5, 7)),
		"bridge destroy target highlighted"
	)
	assert_true(destroy_model.begin_bridge_destroy(), "destroy mode starts")
	var destroy_result := destroy_model.bridge_action_at(Vector2i(5, 7))
	assert_true(destroy_result.success, "bridge destroyed")
	assert_false(destroy_state.board.get_tile(Vector2i(5, 7)).has_bridge, "bridge removed")
	assert_eq(destroy_state.ply, 1, "bridge destroy consumes the turn")
	return true


func test_pass_availability_and_action() -> bool:
	var empty := MovementTestUtils.empty_state()
	assert_not_null(empty, "empty state built")
	if empty == null:
		return true
	var empty_model := PresentationModel.new(empty, PLAYER_1)
	assert_true(empty_model.pass_available(), "pass available with no actions")
	var result := empty_model.pass_turn()
	assert_true(result.success, "pass resolves")
	assert_eq(empty.ply, 1, "pass consumes the turn")
	assert_eq(empty.active_player, PLAYER_2, "pass advances the turn")

	var state := _standard_state()
	assert_not_null(state, "standard state built")
	if state == null:
		return true
	var model := PresentationModel.new(state, PLAYER_1)
	assert_false(model.pass_available(), "pass unavailable while moves exist")
	return true


func test_draw_lifecycle_without_turn_cost() -> bool:
	var state := _standard_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var p1_model := PresentationModel.new(state, PLAYER_1)
	var p2_model := PresentationModel.new(state, PLAYER_2)
	assert_true(p1_model.offer_draw(), "player 1 offers")
	assert_true(p1_model.draw_offered_by_local(), "offer is pending")
	assert_true(p2_model.incoming_draw_offer(), "player 2 sees the offer")
	assert_eq(state.ply, 0, "offer consumes no turn")
	assert_true(p2_model.decline_draw(), "offer declined")
	assert_false(p1_model.draw_offered_by_local(), "offer cleared")
	assert_true(p1_model.offer_draw(), "player 1 offers again")
	assert_true(p2_model.accept_draw(), "player 2 accepts")
	assert_true(state.game_over, "agreement ends the game")
	assert_eq(state.draw_reason, DrawSystem.REASON_AGREEMENT, "agreement reason")
	assert_eq(state.ply, 0, "agreement consumes no turn")
	return true


func test_hidden_enemy_does_not_disable_known_spawn_tile() -> bool:
	var result := MapIO.load_from_file(STANDARD_MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	var observer := MovementTestUtils.add_unit(
		state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 8)
	)
	assert_not_null(observer, "observer placed")
	var hidden_tile := Vector2i(4, 14)
	state.board.get_tile(hidden_tile).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.QUEEN, PLAYER_2, hidden_tile)
	MovementTestUtils.reset_knowledge(state)
	state.add_gold(PLAYER_1, 1)
	var model := PresentationModel.new(state, PLAYER_1)
	assert_false(
		model.view.knowledge.is_enemy_detected(state.get_unit_at(hidden_tile).id),
		"queen is concealed"
	)
	assert_true(model.begin_recruitment(UnitType.Type.PAWN), "recruitment mode starts")
	assert_true(
		model.recruitment_spawn_tiles.has(hidden_tile),
		"concealed occupant does not remove the spawn highlight"
	)
	var recruit_result := model.recruit_at(hidden_tile)
	assert_false(recruit_result.success, "authoritative recruitment rejects the occupied tile")
	assert_eq(state.ply, 0, "rejected recruitment consumes no turn")
	return true


func test_capture_is_logged_and_unit_info_is_known() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var rook := MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_1, Vector2i(8, 8))
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_2, Vector2i(8, 6))
	MovementTestUtils.reset_knowledge(state)
	var model := PresentationModel.new(state, PLAYER_1)
	var info := model.get_unit_info(rook.id)
	assert_false(info.is_empty(), "known unit info exists")
	if not info.is_empty():
		assert_eq(info["name"], "Rook", "unit name")
		assert_eq(int(info["owner"]), PLAYER_1, "unit owner")
		assert_eq(info["terrain"], "Ground", "terrain name")
	model.click_tile(Vector2i(8, 8))
	assert_true(model.capture_destinations.has(Vector2i(8, 6)), "capture destination highlighted")
	assert_eq(
		model.click_tile(Vector2i(8, 6)),
		PresentationModel.ClickResult.ACTION_OK,
		"capture resolves"
	)
	assert_true(_log_contains(model, "Captured Pawn"), "capture is logged")
	return true


func test_mine_visibility_rules() -> bool:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	assert_true(result.is_valid(), "map loads")
	if not result.is_valid():
		return true
	var state := GameState.new(result.map)
	var model := PresentationModel.new(state, PLAYER_1)
	var mine := state.get_gold_mine_at(MINE_A)
	assert_not_null(mine, "mine exists")
	if mine == null:
		return true
	mine.gold_available = true
	assert_false(
		model.visible_gold_token_tiles().has(MINE_A),
		"unseen token is not exposed"
	)
	state.get_knowledge(PLAYER_1).mark_visible(MINE_A)
	assert_true(model.explored_mine_tiles().has(MINE_A), "explored mine is known")
	assert_true(
		model.visible_gold_token_tiles().has(MINE_A),
		"visible token is exposed"
	)
	assert_eq(model.local_occupied_mine_count(), 0, "no mine is occupied locally")
	return true


func test_side_labels_and_winner_text() -> bool:
	var state := _standard_state()
	assert_not_null(state, "state built")
	if state == null:
		return true
	var model := PresentationModel.new(state, PLAYER_1)
	assert_eq(model.side_label(PLAYER_1), "You", "local legacy label")
	assert_eq(model.side_label(PLAYER_2), "Player 2", "legacy opponent label")
	assert_eq(model.short_side_label(PLAYER_2), "P2", "short legacy label")
	assert_eq(model.gold_summary(), "Gold P1 2 · P2 2", "legacy gold summary")
	state.game_over = true
	state.winner = PLAYER_1
	assert_eq(model.winner_text(), "Player 1 wins", "legacy winner text")
	state.winner = GameConfig.NO_PLAYER
	assert_eq(model.winner_text(), "Draw", "draw winner text")

	var ai_model := PresentationModel.new(state, PLAYER_1)
	ai_model.ai_player = PLAYER_2
	assert_eq(ai_model.side_label(PLAYER_1), "You", "local AI-mode label")
	assert_eq(ai_model.side_label(PLAYER_2), "AI", "AI opponent label")
	assert_eq(ai_model.short_side_label(PLAYER_2), "AI", "short AI label")
	assert_eq(ai_model.gold_summary(), "Gold You 2 · AI 2", "AI-mode gold summary")
	state.winner = PLAYER_1
	assert_eq(ai_model.winner_text(), "You win", "local AI-mode win")
	state.winner = PLAYER_2
	assert_eq(ai_model.winner_text(), "AI wins", "AI win")
	return true


func _standard_state() -> GameState:
	var result := MapIO.load_from_file(STANDARD_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load standard map: %s" % str(result.errors))
		return null
	return GameState.new(result.map)


func _promotion_state() -> GameState:
	var state := MovementTestUtils.empty_state()
	if state == null:
		return null
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 1))
	MovementTestUtils.reset_knowledge(state)
	return state


func _engineer_state(bridge_exists: bool) -> GameState:
	var result := MapIO.load_from_file(TERRAIN_MAP_PATH)
	if not result.is_valid():
		push_error("Could not load terrain map: %s" % str(result.errors))
		return null
	var state := GameState.new(result.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.add_unit(state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(4, 7))
	state.board.get_tile(Vector2i(5, 7)).has_bridge = bridge_exists
	MovementTestUtils.reset_knowledge(state)
	return state


func _log_contains(model: PresentationModel, needle: String) -> bool:
	for entry: String in model.log_entries():
		if entry.contains(needle):
			return true
	return false
