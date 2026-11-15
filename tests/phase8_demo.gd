extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2

var _failures: int = 0
var _main: MatchController
var _setup: MatchSetup
var _hud: MobileHud


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080, 2400)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene did not load")
		_finish()
		return
	_main = packed.instantiate() as MatchController
	viewport.add_child(_main)
	await process_frame
	await process_frame
	if _main == null:
		_fail("Main did not use MatchController")
		_finish()
		return
	_main.set_mobile_mode(true)
	_main.set_ai_delay(0.0)
	_setup = _main.get_node_or_null("UI/MatchSetup") as MatchSetup
	_hud = _main.get_node_or_null("UI/MobileHUD") as MobileHud
	if _setup == null or _hud == null:
		_fail("Main is missing setup or the mobile HUD")
		_finish()
		return
	_setup.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	await _start_from_setup()
	await _play_human_and_ai_turn()
	await _rematch_and_return_to_setup()
	_finish()


func _start_from_setup() -> void:
	var primary := _setup.find_child("SetupPrimaryButton", true, false) as Button
	if primary == null:
		_fail("Setup has no primary button")
		return
	_setup.select_mode("vs_ai")
	primary.pressed.emit()
	await process_frame
	if _setup.page_index() != int(MatchSetup.Page.MAP):
		_fail("Setup did not open the map page")
		return
	_setup.select_map("borderlands")
	primary.pressed.emit()
	await process_frame
	if _setup.page_index() != int(MatchSetup.Page.OPTIONS):
		_fail("Setup did not open the side/first-move page")
		return
	_setup.select_side(PLAYER_1)
	_setup.select_first_move(true)
	primary.pressed.emit()
	await process_frame
	await physics_frame
	if _main.state == null or _main.is_setup_visible():
		_fail("Setup did not start the match")
		return
	if _main.model.local_player != PLAYER_1 or _main.model.ai_player != PLAYER_2:
		_fail("Match did not configure You as P1 and the AI as P2")
	print(
		"Setup started: %s, You=P%d, first=%s."
		% [
			_main.current_config.map_display_name(),
			_main.model.local_player,
			_main.current_config.first_label(),
		]
	)


func _play_human_and_ai_turn() -> void:
	_main._on_tile_clicked(Vector2i(4, 14))
	_main._on_tile_clicked(Vector2i(4, 13))
	var log_before := _main.model.log_entries().size()
	var signals := await _wait_ai_turns(1, 3000)
	if signals < 1:
		_fail("AI did not reply to the human move")
		return
	if _main.state.ply != 2 or _main.state.active_player != PLAYER_1:
		_fail("Human plus AI did not complete exactly two plies")
	var entries := _main.model.log_entries()
	var reply := "hidden AI action (no witnessed report)"
	if entries.size() > log_before:
		reply = entries[entries.size() - 1]
	print("AI reply: %s" % reply)
	if not _main.model.can_interact():
		_fail("Human cannot act after the AI reply")


func _rematch_and_return_to_setup() -> void:
	_main.state.game_over = true
	_main.state.winner = PLAYER_1
	_main.state.draw_reason = ""
	_main._refresh_presentation(false)
	if not _hud.is_game_over_visible():
		_fail("Game-over overlay did not appear")
		return
	var rematch := _hud.find_child("GameOverRematchButton", true, false) as Button
	if rematch == null:
		_fail("Game-over rematch button is missing")
		return
	rematch.pressed.emit()
	await process_frame
	if _main.state == null or _main.state.ply != 0 or _main.state.game_over:
		_fail("Rematch did not reset the match")
		return
	var map_id := _main.state.map_id
	var first_player := _main.state.active_player
	print("Rematch reset: map=%s active=P%d." % [map_id, int(first_player)])

	_main.state.game_over = true
	_main.state.winner = PLAYER_1
	_main._refresh_presentation(false)
	var setup_button := _hud.find_child("GameOverSetupButton", true, false) as Button
	if setup_button == null:
		_fail("Game-over setup button is missing")
		return
	setup_button.pressed.emit()
	await process_frame
	if not _main.is_setup_visible() or not _setup.visible:
		_fail("Return to Setup did not open setup")
		return
	if _setup.selected_map_id() != map_id:
		_fail("Setup did not preselect the current map")
	if _setup.selected_human_player() != PLAYER_1:
		_fail("Setup did not preselect the current side")
	print("Return to setup: map=%s, side=P%d." % [map_id, PLAYER_1])


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
	print("Phase 8 demo complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
