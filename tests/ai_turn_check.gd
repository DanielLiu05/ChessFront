extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)

var _failures: int = 0
var _main: MatchController
var _hud: MatchHud
var _board: BoardView


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene did not load")
		_finish()
		return
	_main = packed.instantiate() as MatchController
	root.add_child(_main)
	await process_frame
	await process_frame
	if _main == null:
		_fail("Main did not use MatchController")
		_finish()
		return
	_hud = _main.get_node_or_null("UI/HUD") as MatchHud
	_board = _main.get_node_or_null("Board") as BoardView
	if _hud == null or _board == null:
		_fail("Main is missing the HUD or board")
		_finish()
		return
	await _test_ai_reply_after_human_move()
	await _test_ai_first_locks_and_acts_once()
	await _test_rematch_cancels_old_ai()
	await _test_setup_cancels_ai()
	await _test_hidden_ai_action_does_not_leak()
	await _test_visible_ai_action_is_reported()
	await _test_ai_king_capture_game_over()
	await _test_ai_declines_draw()
	_finish()


func _test_ai_reply_after_human_move() -> void:
	_main.set_ai_delay(0.0)
	if not _main.start_match(
		MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_1)
	):
		_fail("Could not start the human-first match")
		return
	await process_frame
	if _main.state.ply != 0 or _main.state.active_player != PLAYER_1:
		_fail("Human-first match did not start on Player 1")
		return
	_main._on_tile_clicked(Vector2i(4, 14))
	_main._on_tile_clicked(Vector2i(4, 13))
	var signals := await _wait_ai_turns(1, 3000)
	if signals < 1:
		_fail("AI did not reply after the human move")
		return
	if _main.state.ply != 2 or _main.state.active_player != PLAYER_1:
		_fail("AI reply did not consume exactly one ply")
	if _main.is_ai_thinking() or _main.is_ai_turn_running():
		_fail("AI flags were not cleared after the reply")
	if not _main.model.can_interact():
		_fail("Human should be able to act after the AI reply")


func _test_ai_first_locks_and_acts_once() -> void:
	_main.set_ai_delay(0.2)
	if not _main.start_match(
		MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_2)
	):
		_fail("Could not start the AI-first match")
		return
	if not _main.is_ai_turn_running() or not _main.is_ai_thinking():
		_fail("AI-first did not begin automatically")
	if _main.state.active_player != PLAYER_2:
		_fail("AI-first did not set Player 2 active")
	var status := _hud.get_node("%StatusLabel") as Label
	if status == null or not status.text.contains("AI is thinking"):
		_fail("HUD did not report AI thinking")
	_main._on_tile_clicked(Vector2i(4, 14))
	if _main.model.selected_unit() != null or _main.state.ply != 0:
		_fail("Human input was not locked during the AI turn")
	var signals := await _wait_ai_turns(1, 3000)
	if signals < 1:
		_fail("AI-first did not complete a turn")
		return
	await create_timer(0.5).timeout
	if _main.state.ply != 1:
		_fail("AI acted more than once in one turn")
	if _main.state.active_player != PLAYER_1 or not _main.model.can_interact():
		_fail("AI-first did not hand the turn back")
	if _main.is_ai_thinking() or _main.is_ai_turn_running():
		_fail("AI flags remained set after the AI-first turn")


func _test_rematch_cancels_old_ai() -> void:
	_main.set_ai_delay(0.25)
	if not _main.start_match(
		MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_2)
	):
		_fail("Could not start the rematch-cancel match")
		return
	if not _main.rematch():
		_fail("Rematch did not start")
		return
	var signals := await _wait_ai_turns(1, 2500)
	if signals != 1:
		_fail("Old AI work survived a rematch: %d turns" % signals)
	if _main.state.ply != 1:
		_fail("Rematch allowed more than one AI action")


func _test_setup_cancels_ai() -> void:
	_main.set_ai_delay(0.25)
	if not _main.start_match(
		MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_2)
	):
		_fail("Could not start the setup-cancel match")
		return
	_main.return_to_setup()
	await process_frame
	if not _main.is_setup_visible():
		_fail("Return to Setup did not open setup")
	await create_timer(0.7).timeout
	if _main.state.ply != 0:
		_fail("AI acted after setup was opened")
	if _main.is_ai_thinking() or _main.is_ai_turn_running():
		_fail("AI flags remained set after setup cancellation")


func _test_hidden_ai_action_does_not_leak() -> void:
	var state := MovementTestUtils.empty_state()
	if state == null:
		_fail("Could not build the hidden AI state")
		return
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_2, Vector2i(8, 1))
	state.active_player = PLAYER_2
	state.refresh_vision()
	_assign_state(state, PLAYER_2)
	await process_frame
	var signals := await _wait_ai_turns(1, 3000)
	if signals < 1:
		_fail("Hidden AI action did not finish")
		return
	if _main.state.ply != 1:
		_fail("Hidden AI action did not consume one ply")
	if not _main.model.log_entries().is_empty():
		_fail("Hidden AI action leaked a log entry: %s" % str(_main.model.log_entries()))
	if _board.get_visible_unit_ids().size() != 1:
		_fail("Hidden AI action created a visible piece")


func _test_visible_ai_action_is_reported() -> void:
	var state := MovementTestUtils.empty_state()
	if state == null:
		_fail("Could not build the visible AI state")
		return
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_1, Vector2i(8, 10))
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_2, Vector2i(8, 6))
	state.active_player = PLAYER_2
	state.refresh_vision()
	_assign_state(state, PLAYER_2)
	await process_frame
	var signals := await _wait_ai_turns(1, 3000)
	if signals < 1:
		_fail("Visible AI action did not finish")
		return
	var found := false
	for entry: String in _main.model.log_entries():
		if entry.contains("AI's Rook"):
			found = true
			break
	if not found:
		_fail("Visible AI action was not reported: %s" % str(_main.model.log_entries()))
	if _main.state.ply != 1 or _main.state.active_player != PLAYER_1:
		_fail("Visible AI action did not advance the turn")


func _test_ai_king_capture_game_over() -> void:
	var state := MovementTestUtils.empty_state()
	if state == null:
		_fail("Could not build the AI game-over state")
		return
	MovementTestUtils.add_unit(state, UnitType.Type.KING, PLAYER_1, CENTER)
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_2, Vector2i(8, 5))
	state.board.get_tile(Vector2i(8, 6)).terrain = TerrainType.Type.FOREST
	MovementTestUtils.add_unit(state, UnitType.Type.ROOK, PLAYER_2, Vector2i(8, 6))
	state.active_player = PLAYER_2
	state.refresh_vision()
	_assign_state(state, PLAYER_2)
	await process_frame
	var signals := await _wait_ai_turns(1, 3000)
	if signals < 1:
		_fail("AI King capture did not finish")
		return
	if not _main.state.game_over or _main.state.winner != PLAYER_2:
		_fail("AI King capture did not end the game for the AI")
	var title := _hud.get_node("%GameOverTitle") as Label
	if title == null or title.text != "AI wins":
		_fail("AI game-over title is wrong: %s" % (title.text if title else "missing"))
	var loss_reported := false
	for entry: String in _main.model.log_entries():
		if entry.contains("Your King was captured"):
			loss_reported = true
		if entry.contains("Rook"):
			_fail("Hidden AI attacker was revealed: %s" % entry)
	if not loss_reported:
		_fail("AI King capture did not report the local unit loss")


func _test_ai_declines_draw() -> void:
	_main.set_ai_delay(0.0)
	if not _main.start_match(
		MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_1)
	):
		_fail("Could not start the draw-decline match")
		return
	await process_frame
	_main._on_offer_draw_requested()
	await process_frame
	await process_frame
	if _main.state.draw_offered_by != GameConfig.NO_PLAYER:
		_fail("AI did not decline the draw offer")
	if _main.state.ply != 0:
		_fail("Draw decline consumed a turn")
	var found := false
	for entry: String in _main.model.log_entries():
		if entry.contains("AI declined"):
			found = true
			break
	if not found:
		_fail("AI draw decline was not logged")


func _assign_state(state: GameState, ai_player: int) -> void:
	_main._cancel_ai_work()
	_main.state = state
	_main.model = PresentationModel.new(state, PLAYER_1)
	_main.model.ai_player = ai_player
	_main.current_config = null
	_main._ai_brain = AiBrain.new()
	_board.build(state.board)
	_main.hide_setup()
	_main._refresh_presentation(true)
	_main._maybe_start_ai_turn()


func _wait_ai_turns(minimum: int, timeout_ms: int) -> int:
	var observed: Array[int] = [0]
	var handler := func() -> void: observed[0] += 1
	_main.ai_turn_finished.connect(handler)
	var deadline := Time.get_ticks_msec() + timeout_ms
	while observed[0] < minimum and Time.get_ticks_msec() < deadline:
		await process_frame
	if observed[0] >= minimum:
		var quiet_deadline := Time.get_ticks_msec() + 250
		while Time.get_ticks_msec() < quiet_deadline:
			await process_frame
	_main.ai_turn_finished.disconnect(handler)
	return observed[0]


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish() -> void:
	MobileMetrics.clear_dpi_override()
	print("AI turn check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
