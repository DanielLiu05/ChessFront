extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2

var _failures: int = 0


func _initialize() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene did not load")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var controller := main as MatchController
	if controller == null:
		push_error("Main did not use MatchController")
		_failures += 1
	elif not controller.load_map("borderlands"):
		push_error("Could not start the UI flow match")
		_failures += 1
	else:
		await _run_flow(controller)
	print("UI flow check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _run_flow(controller: MatchController) -> void:
	var board := controller.get_node_or_null("Board") as BoardView
	var hud := controller.get_node_or_null("UI/HUD") as MatchHud
	if board == null or hud == null or controller.model == null or controller.state == null:
		push_error("UI flow scene is missing board, HUD, model or state")
		_failures += 1
		return
	var state := controller.state
	var turn_label := hud.get_node("%TurnLabel") as Label
	var pass_button := hud.get_node("%PassButton") as Button
	var log_label := hud.get_node("%LogLabel") as Label
	if state.active_player != PLAYER_1:
		_failures += 1
		push_error("Player 1 should start active")
	if board.get_visible_unit_ids().size() != 16:
		_failures += 1
		push_error("Player 1 should see its 16 pieces at start")
	if board.get_tile_view(Vector2i(0, 8)).get_fog_state() != TileView.FogState.UNEXPLORED:
		_failures += 1
		push_error("A far tile should be unexplored")
	if not turn_label.text.contains("Your turn"):
		_failures += 1
		push_error("HUD should show the local turn")
	if not pass_button.disabled:
		_failures += 1
		push_error("Pass should be disabled while moves exist")

	var pawn := state.get_unit_at(Vector2i(4, 14))
	if pawn == null:
		_failures += 1
		push_error("Player 1 pawn is missing")
		return
	controller._on_tile_clicked(Vector2i(4, 14))
	if not board.has_highlight(Vector2i(4, 13)):
		_failures += 1
		push_error("Legal destination should be highlighted")
	controller._on_tile_clicked(Vector2i(4, 13))
	await create_timer(0.5).timeout
	if state.ply != 1 or state.active_player != PLAYER_2:
		_failures += 1
		push_error("Move should consume one ply and pass the turn")
	if pawn.tile != Vector2i(4, 13):
		_failures += 1
		push_error("Pawn should be at the new tile")
	var piece := board.get_piece_view(pawn.id)
	if piece == null or piece.tile != Vector2i(4, 13):
		_failures += 1
		push_error("Piece view should follow the move")
	if not turn_label.text.contains("waiting"):
		_failures += 1
		push_error("HUD should show the waiting state for Player 2")

	if not controller.load_map("borderlands"):
		_failures += 1
		push_error("Could not reset the match")
		return
	await process_frame
	MovementTestUtils.clear_gold(controller.state)
	controller.state.add_gold(PLAYER_1, 1)
	controller._refresh_presentation(false)
	hud.recruit_requested.emit(UnitType.Type.PAWN)
	await process_frame
	if controller.model.recruitment_type() != UnitType.Type.PAWN:
		_failures += 1
		push_error("Recruitment mode should start")
		return
	if controller.model.recruitment_spawn_tiles.is_empty():
		_failures += 1
		push_error("Recruitment should highlight spawn tiles")
		return
	var spawn := controller.model.recruitment_spawn_tiles[0]
	controller._on_tile_clicked(spawn)
	await create_timer(0.5).timeout
	if controller.state.active_player != PLAYER_2:
		_failures += 1
		push_error("Recruitment should consume the turn")
	if controller.state.get_gold(PLAYER_1) != 0:
		_failures += 1
		push_error("Recruitment should spend the gold")
	if controller.state.count_units_for_player(PLAYER_1) != 17:
		_failures += 1
		push_error("Recruited pawn should be on the board")
	if board.get_visible_unit_ids().size() != 17:
		_failures += 1
		push_error("Recruited pawn should have a piece view")
	if not log_label.text.contains("Recruited Pawn"):
		_failures += 1
		push_error("Action log should record the recruitment")

	var standard := MapIO.load_from_file("res://maps/standard_template.json")
	if not standard.is_valid():
		_failures += 1
		push_error("Could not load the standard map for UI scenarios")
		return
	var promotion_state := GameState.new(standard.map)
	MovementTestUtils.clear_units(promotion_state)
	var promotion_pawn := MovementTestUtils.add_unit(
		promotion_state, UnitType.Type.PAWN, PLAYER_1, Vector2i(8, 1)
	)
	MovementTestUtils.reset_knowledge(promotion_state)
	_assign_state(controller, promotion_state, board)
	controller._on_tile_clicked(Vector2i(8, 1))
	controller._on_tile_clicked(Vector2i(8, 0))
	await process_frame
	var promotion_overlay := hud.get_node("%PromotionOverlay") as Control
	if not promotion_overlay.visible:
		_failures += 1
		push_error("Promotion overlay should be visible")
	hud.promotion_selected.emit(UnitType.Type.KNIGHT)
	await create_timer(0.5).timeout
	if promotion_pawn.type != UnitType.Type.KNIGHT:
		_failures += 1
		push_error("Promotion choice should apply")
	if promotion_state.ply != 1:
		_failures += 1
		push_error("Promotion should consume one turn")
	if promotion_overlay.visible:
		_failures += 1
		push_error("Promotion overlay should hide after resolution")

	var terrain := MapIO.load_from_file("res://maps/terrain_showcase.json")
	if not terrain.is_valid():
		_failures += 1
		push_error("Could not load the terrain map for the bridge scenario")
		return
	var bridge_state := GameState.new(terrain.map)
	MovementTestUtils.clear_units(bridge_state)
	MovementTestUtils.add_unit(
		bridge_state, UnitType.Type.ENGINEER, PLAYER_1, Vector2i(4, 7)
	)
	MovementTestUtils.reset_knowledge(bridge_state)
	_assign_state(controller, bridge_state, board)
	controller._on_tile_clicked(Vector2i(4, 7))
	await process_frame
	var build_button := hud.get_node("%BuildBridgeButton") as Button
	if build_button.disabled:
		_failures += 1
		push_error("Build Bridge should be enabled for the engineer")
	hud.bridge_build_requested.emit()
	await process_frame
	controller._on_tile_clicked(Vector2i(5, 7))
	await create_timer(0.5).timeout
	if not bridge_state.board.get_tile(Vector2i(5, 7)).has_bridge:
		_failures += 1
		push_error("Bridge HUD action should build the bridge")
	if bridge_state.ply != 1:
		_failures += 1
		push_error("Bridge construction should consume one turn")

	var pass_state := GameState.new(standard.map)
	MovementTestUtils.clear_units(pass_state)
	MovementTestUtils.clear_gold(pass_state)
	MovementTestUtils.reset_knowledge(pass_state)
	_assign_state(controller, pass_state, board)
	await process_frame
	var pass_state_button := hud.get_node("%PassButton") as Button
	if pass_state_button.disabled:
		_failures += 1
		push_error("Pass should be enabled when no action exists")
	hud.pass_requested.emit()
	await create_timer(0.3).timeout
	if pass_state.ply != 1 or pass_state.active_player != PLAYER_2:
		_failures += 1
		push_error("Pass HUD action should advance the turn")

	var draw_state := GameState.new(standard.map)
	MovementTestUtils.clear_units(draw_state)
	MovementTestUtils.reset_knowledge(draw_state)
	_assign_state(controller, draw_state, board)
	await process_frame
	DrawSystem.offer_draw(draw_state, PLAYER_2)
	controller._refresh_presentation(false)
	var accept_button := hud.get_node("%AcceptDrawButton") as Button
	var decline_button := hud.get_node("%DeclineDrawButton") as Button
	if not accept_button.visible or not decline_button.visible:
		_failures += 1
		push_error("Incoming draw controls should be visible")
	hud.decline_draw_requested.emit()
	await process_frame
	if draw_state.draw_offered_by != GameConfig.NO_PLAYER or draw_state.game_over:
		_failures += 1
		push_error("Declining a draw should clear the offer without ending the game")
	if draw_state.ply != 0:
		_failures += 1
		push_error("Draw actions should not consume a turn")
	DrawSystem.offer_draw(draw_state, PLAYER_2)
	controller._refresh_presentation(false)
	hud.accept_draw_requested.emit()
	await process_frame
	if not draw_state.game_over or draw_state.draw_reason != DrawSystem.REASON_AGREEMENT:
		_failures += 1
		push_error("Accepting a draw should end the game by agreement")
	if draw_state.ply != 0:
		_failures += 1
		push_error("Accepting a draw should not consume a turn")
	var game_over_overlay := hud.get_node("%GameOverOverlay") as Control
	var game_over_title := hud.get_node("%GameOverTitle") as Label
	var game_over_detail := hud.get_node("%GameOverDetail") as Label
	if not game_over_overlay.visible:
		_failures += 1
		push_error("Game-over overlay should be visible")
	if not game_over_title.text.contains("Draw"):
		_failures += 1
		push_error("Game-over title should report a draw")
	if not game_over_detail.text.contains("agreed"):
		_failures += 1
		push_error("Game-over detail should explain the agreement")

	if not controller.start_match(
		MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_1)
	):
		_failures += 1
		push_error("Could not start the production lifecycle match")
		return
	await process_frame
	controller.state.game_over = true
	controller.state.draw_reason = DrawSystem.REASON_AGREEMENT
	controller.state.winner = GameConfig.NO_PLAYER
	controller._refresh_presentation(false)
	hud.rematch_requested.emit()
	await process_frame
	if controller.state.map_id != "borderlands" or controller.state.game_over:
		_failures += 1
		push_error("Rematch should reload the same map")
	if game_over_overlay.visible:
		_failures += 1
		push_error("Game-over overlay should hide on a rematch")
	if controller.current_config == null:
		_failures += 1
		push_error("Rematch should keep the production config")
	var help_dialog := hud.get_node("%HelpDialog") as AcceptDialog
	if not help_dialog.dialog_text.contains("Right drag"):
		_failures += 1
		push_error("Help dialog should describe camera controls")

	hud.offer_draw_requested.emit()
	await process_frame
	if controller.state.draw_offered_by != PLAYER_1 or controller.state.ply != 0:
		_failures += 1
		push_error("Local draw offer should be pending and cost no turn")
	hud.rematch_requested.emit()
	await process_frame

	var reason_cases := {
		DrawSystem.REASON_TURN_LIMIT: "turn limit",
		DrawSystem.REASON_THREEFOLD: "three times",
	}
	for reason: String in reason_cases:
		controller.state.game_over = true
		controller.state.draw_reason = reason
		controller.state.winner = GameConfig.NO_PLAYER
		controller._refresh_presentation(false)
		if not game_over_overlay.visible:
			_failures += 1
			push_error("Game-over overlay should show for %s" % reason)
		if not game_over_detail.text.contains(String(reason_cases[reason])):
			_failures += 1
			push_error("Game-over detail should describe %s" % reason)
		hud.rematch_requested.emit()
		await process_frame
	controller.state.game_over = true
	controller.state.draw_reason = ""
	controller.state.winner = PLAYER_1
	controller._refresh_presentation(false)
	if not game_over_title.text.contains("You win"):
		_failures += 1
		push_error("King-capture game over should name the local winner")
	if not game_over_detail.text.contains("King"):
		_failures += 1
		push_error("King-capture game over should describe the capture")
	var rematch_button := hud.get_node("%GameOverRematchButton") as Button
	var setup_button := hud.get_node("%GameOverSetupButton") as Button
	if rematch_button == null or setup_button == null:
		_failures += 1
		push_error("Game-over overlay should offer rematch and setup")
	else:
		rematch_button.pressed.emit()
		await process_frame
		if controller.state.ply != 0 or controller.state.game_over:
			_failures += 1
			push_error("Game-over rematch should reset the same match")
	var return_setup := hud.get_node("%ReturnSetupButton") as Button
	var setup_dialog := hud.get_node("%SetupConfirmDialog") as ConfirmationDialog
	if return_setup == null or setup_dialog == null:
		_failures += 1
		push_error("Desktop HUD should expose the setup return and confirmation")
	else:
		return_setup.pressed.emit()
		setup_dialog.confirmed.emit()
		await process_frame
		if not controller.is_setup_visible():
			_failures += 1
			push_error("Return to Setup should show the setup screen")
		if hud.visible:
			_failures += 1
			push_error("Desktop HUD should hide while setup is open")
		controller.hide_setup()
		await process_frame

	if _failures == 0:
		print(
			"UI flow: fog, selection, move, waiting, recruitment, promotion, bridge, pass, draw controls, game-over rematch and setup return passed"
		)


func _assign_state(
	controller: MatchController,
	state: GameState,
	board: BoardView
) -> void:
	controller.state = state
	controller.model = PresentationModel.new(state, PLAYER_1)
	board.build(state.board)
	controller._refresh_presentation(true)
