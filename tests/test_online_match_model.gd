extends TestCase

const MAP_ID: String = "borderlands"
const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2


func test_model_selection_and_hidden_information() -> bool:
	var loaded := MapLibrary.load_by_id(MAP_ID)
	var state := GameState.new(loaded.map)
	var client_state := _client_state(state, loaded.map, PLAYER_1)
	assert_not_null(client_state, "client state builds")
	if client_state == null:
		return true
	var model := OnlineMatchModel.new(client_state)
	assert_eq(model.local_player, PLAYER_1, "local player is retained")
	assert_eq(model.side_label(PLAYER_1), "You", "own side is You")
	assert_eq(model.side_label(PLAYER_2), "Opponent", "other side is Opponent")
	assert_eq(model.gold_summary(), "Gold You 2 · Opponent ?", "enemy gold is hidden")
	assert_true(model.can_interact(), "the first player can interact")
	assert_true(model.has_state(), "online model has a state")
	assert_false(model.is_game_over(), "the match is not over")
	assert_eq(model.ply(), 0, "ply starts at zero")
	assert_eq(model.turn_limit_plies(), 200, "turn limit is carried")
	assert_true(model.view is PlayerView, "view is a PlayerView")
	for unit: GameUnit in model.view.get_known_units():
		if unit.owner == PLAYER_1:
			continue
		assert_true(model.view.knowledge.is_enemy_detected(unit.id), "only detected enemies are known")
	assert_true(model.view.get_known_units().size() < state.units.size(), "the view is fog-limited")
	assert_false(model.select_unit_at(Vector2i(5, 0)), "enemy units cannot be selected")
	assert_true(model.select_unit_at(Vector2i(4, 14)), "own pawn can be selected")
	assert_false(model.legal_destinations.is_empty(), "selection highlights legal destinations")
	var click := model.click_tile(Vector2i(4, 13))
	assert_eq(click, OnlineMatchModel.ClickResult.ACTION_OK, "clicking a destination prepares an intent")
	var action := model.consume_action()
	assert_true(action is MoveAction, "the prepared intent is a MoveAction")
	assert_eq(model.ply(), 0, "preparing an intent does not change the ply")
	assert_null(model.selected_unit(), "the selection is cleared after taking the intent")
	return true


func test_promotion_and_pass_intents() -> bool:
	var loaded := MapIO.load_from_file("res://maps/standard_template.json")
	if not loaded.is_valid():
		assert_true(false, "standard map loads")
		return true
	var state := GameState.new(loaded.map)
	MovementTestUtils.clear_units(state)
	MovementTestUtils.add_unit(state, UnitType.Type.PAWN, PLAYER_1, Vector2i(5, 1))
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 0))
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_1, Vector2i(8, 15))
	MovementTestUtils.clear_gold(state)
	state.refresh_vision()
	var client_state := _client_state(state, loaded.map, PLAYER_1)
	var model := OnlineMatchModel.new(client_state)
	assert_true(model.select_unit_at(Vector2i(5, 1)), "promotion pawn is selected")
	var click := model.click_tile(Vector2i(5, 0))
	assert_eq(click, OnlineMatchModel.ClickResult.PROMOTION_REQUIRED, "promotion is required")
	assert_true(model.has_pending_promotion(), "promotion is pending")
	var action := model.complete_promotion_action(UnitType.Type.ROOK)
	assert_true(action is MoveAction, "promotion produces a move intent")
	if action is MoveAction:
		assert_eq((action as MoveAction).promotion_type, UnitType.Type.ROOK, "chosen promotion is kept")
	model.cancel_recruitment()
	model.clear_selection()
	assert_false(model.pass_available(), "pass is unavailable when a move exists")
	assert_null(model.pass_action(), "no pass intent is produced")

	MovementTestUtils.clear_units(state)
	MovementTestUtils.clear_gold(state)
	MovementTestUtils.reset_knowledge(state)
	var empty_client := _client_state(state, loaded.map, PLAYER_1)
	var empty_model := OnlineMatchModel.new(empty_client)
	assert_true(empty_model.pass_available(), "pass is available with no units or actions")
	var pass_action := empty_model.pass_action()
	assert_true(pass_action is PassAction, "pass intent is produced")
	return true


func test_recruit_and_bridge_intents() -> bool:
	var loaded := MapLibrary.load_by_id(MAP_ID)
	var state := GameState.new(loaded.map)
	state.deployment_tiles[PLAYER_1] = [Vector2i(3, 14)]
	state.refresh_vision()
	var client_state := _client_state(state, loaded.map, PLAYER_1)
	var model := OnlineMatchModel.new(client_state)
	assert_eq(model.own_gold(), GameConfig.STARTING_GOLD, "own gold comes from the view")
	assert_true(model.can_recruit_unit(UnitType.Type.PAWN), "pawn is affordable")
	assert_false(model.can_recruit_unit(UnitType.Type.ROOK), "expensive units are not affordable")
	assert_true(model.begin_recruitment(UnitType.Type.PAWN), "recruitment mode starts")
	assert_true(Vector2i(3, 14) in model.recruitment_spawn_tiles, "free deployment tile is offered")
	assert_eq(
		model.click_tile(Vector2i(3, 14)),
		OnlineMatchModel.ClickResult.ACTION_OK,
		"clicking a spawn tile prepares recruitment"
	)
	var recruit := model.consume_action()
	assert_true(recruit is RecruitAction, "recruitment intent is produced")

	var bridge_loaded := MapLibrary.load_by_id("river_crossing")
	var bridge_state := GameState.new(bridge_loaded.map)
	MovementTestUtils.clear_units(bridge_state)
	var water := _find_water_neighbor(bridge_state)
	assert_true(water["tile"] != Vector2i(-1, -1), "a water bridge target exists")
	if water["tile"] == Vector2i(-1, -1):
		return true
	var engineer_tile := water["adjacent"] as Vector2i
	MovementTestUtils.add_unit(
		bridge_state, UnitType.Type.ENGINEER, PLAYER_1, engineer_tile
	)
	MovementTestUtils.add_unit(
		bridge_state, UnitType.Type.KING, PLAYER_2, Vector2i(8, 0)
	)
	bridge_state.refresh_vision()
	var knowledge := bridge_state.get_knowledge(PLAYER_1)
	knowledge.explored[engineer_tile] = true
	knowledge.visible[engineer_tile] = true
	knowledge.explored[water["tile"]] = true
	knowledge.visible[water["tile"]] = true
	var bridge_client := _client_state(bridge_state, bridge_loaded.map, PLAYER_1)
	var bridge_model := OnlineMatchModel.new(bridge_client)
	assert_true(bridge_model.select_unit_at(engineer_tile), "engineer is selected")
	assert_true(water["tile"] in bridge_model.bridge_build_targets, "water tile is a bridge target")
	assert_true(bridge_model.begin_bridge_build(), "bridge build mode starts")
	assert_eq(
		bridge_model.click_tile(water["tile"]),
		OnlineMatchModel.ClickResult.ACTION_OK,
		"clicking the target prepares a bridge intent"
	)
	var bridge_action := bridge_model.consume_action()
	assert_true(bridge_action is BuildBridgeAction, "bridge intent is produced")
	return true


func test_draw_and_game_over_flags() -> bool:
	var loaded := MapLibrary.load_by_id(MAP_ID)
	var state := GameState.new(loaded.map)
	var client_state := _client_state(state, loaded.map, PLAYER_1)
	var model := OnlineMatchModel.new(client_state)
	assert_true(model.can_offer_draw(), "draw can be offered at the start")
	assert_false(model.draw_offered_by_local(), "no local offer is pending")
	client_state.draw_offered_by = PLAYER_2
	assert_true(model.incoming_draw_offer(), "opponent offers are detected")
	assert_false(model.can_offer_draw(), "a pending offer blocks another offer")
	client_state.draw_offered_by = PLAYER_1
	assert_true(model.draw_offered_by_local(), "local offers are detected")
	assert_false(model.incoming_draw_offer(), "a local offer is not incoming")
	client_state.draw_offered_by = GameConfig.NO_PLAYER
	client_state.game_over = true
	client_state.winner = PLAYER_1
	assert_true(model.is_game_over(), "game over is exposed")
	assert_eq(model.winner_text(), "You win", "local winner text")
	assert_false(model.can_interact(), "no interaction after game over")
	client_state.winner = PLAYER_2
	assert_eq(model.winner_text(), "Opponent wins", "opponent winner text")
	client_state.winner = GameConfig.NO_PLAYER
	client_state.draw_reason = DrawSystem.REASON_AGREEMENT
	assert_eq(model.winner_text(), "Draw", "draw text")
	assert_eq(model.game_draw_reason(), DrawSystem.REASON_AGREEMENT, "draw reason is exposed")
	return true


func _client_state(state: GameState, map: MapData, player: int) -> ClientMatchState:
	var view := NetworkViewCodec.encode(
		state,
		PlayerView.for_player(state, player),
		player
	)
	return ClientMatchState.from_view(view, map, {
		"map_id": map.id,
		"map_format_version": map.format_version,
		"player": player,
		"first_player": GameConfig.FIRST_PLAYER,
	})


func _find_water_neighbor(state: GameState) -> Dictionary:
	for tile: Vector2i in state.board.get_playable_tiles():
		var data := state.board.get_tile(tile)
		if data.terrain != TerrainType.Type.WATER:
			continue
		for direction: Vector2i in BoardData.DIRECTIONS:
			var neighbor := tile + direction
			if not state.board.is_playable(neighbor):
				continue
			if not state.board.is_passable(neighbor):
				continue
			if state.is_occupied(neighbor):
				continue
			return {"tile": tile, "adjacent": neighbor}
	return {"tile": Vector2i(-1, -1), "adjacent": Vector2i(-1, -1)}
