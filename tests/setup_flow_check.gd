extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2

var _failures: int = 0
var _controller: MatchController
var _setup: MatchSetup
var _mobile_hud: MobileHud
var _desktop_hud: MatchHud
var _board: BoardView


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
	_controller = packed.instantiate() as MatchController
	viewport.add_child(_controller)
	await process_frame
	await process_frame
	if _controller == null:
		_fail("Main did not use MatchController")
		_finish()
		return
	_setup = _controller.get_node_or_null("UI/MatchSetup") as MatchSetup
	_mobile_hud = _controller.get_node_or_null("UI/MobileHUD") as MobileHud
	_desktop_hud = _controller.get_node_or_null("UI/HUD") as MatchHud
	_board = _controller.get_node_or_null("Board") as BoardView
	if _setup == null or _mobile_hud == null or _desktop_hud == null or _board == null:
		_fail("Main is missing the setup, HUD or board nodes")
		_finish()
		return
	_setup.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	_controller.set_mobile_mode(true)
	await process_frame
	await _test_setup_first_boot()
	await _test_setup_flow_to_match()
	await _test_local_side_and_camera()
	await _test_setup_return_and_input_gating()
	await _test_direct_load_map()
	await _test_invalid_start()
	_finish()


func _test_setup_first_boot() -> void:
	if not _controller.is_setup_visible():
		_fail("Setup should be visible at boot")
	if not _setup.visible:
		_fail("Setup node should be visible at boot")
	if _controller.state != null or _controller.model != null:
		_fail("No match should be active at boot")
	if _desktop_hud.visible or _mobile_hud.visible:
		_fail("Match HUDs should be hidden during setup")
	if _setup.page_index() != int(MatchSetup.Page.MODE):
		_fail("Setup should start on the mode page")
	if _setup.mode_count() != 1:
		_fail("Setup should offer exactly one mode")
	if _setup.map_count() < 3:
		_fail("Setup should list the shipped map library")
	if _setup.selected_mode_id() != "vs_ai":
		_fail("The AI mode should be preselected")
	if _setup.selected_human_player() != PLAYER_1:
		_fail("Player 1 should be the default side")
	if not _setup.selected_first_is_human():
		_fail("The human should move first by default")
	if not _setup.error_text().is_empty():
		_fail("Default setup should have no error: %s" % _setup.error_text())


func _test_setup_flow_to_match() -> void:
	var primary := _setup.find_child("SetupPrimaryButton", true, false) as Button
	if primary == null:
		_fail("Setup has no primary button")
		return
	primary.pressed.emit()
	await process_frame
	if _setup.page_index() != int(MatchSetup.Page.MAP):
		_fail("Continue did not open the map page")
	_setup.select_map("river_crossing")
	primary.pressed.emit()
	await process_frame
	if _setup.page_index() != int(MatchSetup.Page.OPTIONS):
		_fail("Continue did not open the side/first-move page")
	_setup.select_side(PLAYER_2)
	_setup.select_first_move(false)
	if _setup.selected_map_id() != "river_crossing":
		_fail("Map selection did not stick")
	if _setup.selected_human_player() != PLAYER_2:
		_fail("Side selection did not stick")
	if _setup.selected_first_is_human():
		_fail("First-move selection did not stick")
	if not _setup.is_start_enabled():
		_fail("Start should be enabled for a valid setup")
	if not _setup.current_config().summary_text().contains("AI"):
		_fail("Setup summary should name the AI first move")
	primary.pressed.emit()
	await process_frame
	await physics_frame
	await process_frame
	if _setup.visible or _controller.is_setup_visible():
		_fail("Starting a match should hide setup")
	if _controller.state == null or _controller.model == null:
		_fail("Starting a match should create state and a local model")
		return
	if _controller.state.map_id != "river_crossing":
		_fail("Selected map was not loaded")
	if _controller.model.local_player != PLAYER_2:
		_fail("Local view should use the selected side")
	if _controller.state.active_player != PLAYER_1:
		_fail("AI side should be the first player")
	if _controller.current_config == null:
		_fail("Controller should keep the started config")
	if not _mobile_hud.visible:
		_fail("Mobile HUD should appear after starting")
	if _desktop_hud.visible:
		_fail("Desktop HUD should stay hidden in mobile mode")
	if _board.get_visible_unit_ids().size() != 16:
		_fail("Local player 2 should see its 16 pieces")


func _test_local_side_and_camera() -> void:
	var camera := _controller.get_node_or_null("CameraRig") as CameraRig
	if camera == null:
		_fail("Camera rig is missing")
		return
	if not is_equal_approx(camera.get_side_orientation_degrees(), 180.0):
		_fail("Playing Player 2 should flip the fixed side orientation")
	if not is_equal_approx(camera.yaw_degrees, 180.0):
		_fail("Mobile camera yaw should be fixed at 180 for Player 2")
	var p2_screen := _board.screen_position_for_tile(Vector2i(4, 1))
	var p1_screen := _board.screen_position_for_tile(Vector2i(4, 14))
	if p2_screen.y <= p1_screen.y:
		_fail(
			"Local Player 2 army should be at the bottom: p2=%s p1=%s"
			% [str(p2_screen), str(p1_screen)]
		)
	var human_first := MatchConfig.new("vs_ai", "borderlands", PLAYER_2, PLAYER_2)
	if not _controller.start_match(human_first):
		_fail("Could not start a Player 2 / human-first match")
		return
	await process_frame
	if _controller.state.active_player != PLAYER_2:
		_fail("Human-first config should make Player 2 active")
	if not _controller.model.can_interact():
		_fail("Local Player 2 should be able to act")
	_controller._on_tile_clicked(Vector2i(4, 1))
	if _controller.model.selected_unit() == null:
		_fail("Player 2 pawn should be selectable")
		return
	var destination := _controller.model.legal_destinations[0]
	_controller._on_tile_clicked(destination)
	await create_timer(0.4).timeout
	if _controller.state.ply != 1:
		_fail("A Player 2 move should consume one ply")
	if _controller.state.active_player != PLAYER_1:
		_fail("Turn should pass to Player 1")
	if not _controller.rematch():
		_fail("Rematch should start from the current config")
		return
	await process_frame
	if _controller.state.ply != 0 or _controller.state.active_player != PLAYER_2:
		_fail("Rematch should reset the same first player")
	if _controller.model.local_player != PLAYER_2:
		_fail("Rematch should keep the human side")
	if _controller.current_config == null \
			or _controller.current_config.map_id != "borderlands" \
			or _controller.current_config.human_player != PLAYER_2 \
			or _controller.current_config.first_player != PLAYER_2:
		_fail("Rematch should keep the complete config")


func _test_setup_return_and_input_gating() -> void:
	_controller.show_setup()
	await process_frame
	if not _setup.visible or not _controller.is_setup_visible():
		_fail("Returning to setup should show the setup screen")
	if _mobile_hud.visible:
		_fail("HUD should hide while setup is open")
	if _setup.selected_human_player() != PLAYER_2:
		_fail("Returning to setup should preselect the current side")
	if _controller.handle_back_request() == false:
		_fail("Back should be consumed by setup")
	if _setup.page_index() != int(MatchSetup.Page.MODE):
		_fail("Setup should remain on the mode page at the root")
	_setup.go_to_map_page()
	await process_frame
	if not _controller.handle_back_request():
		_fail("Back should leave the map page")
	if _setup.page_index() != int(MatchSetup.Page.MODE):
		_fail("Back from the map page should return to mode")
	_setup.go_to_map_page()
	await process_frame
	_controller._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await process_frame
	if _setup.page_index() != int(MatchSetup.Page.MODE):
		_fail("Android back should leave the map page")
	_setup.go_to_map_page()
	_setup.go_to_options_page()
	await process_frame
	if not _controller.handle_back_request():
		_fail("Back should leave the options page")
	if _setup.page_index() != int(MatchSetup.Page.MAP):
		_fail("Back from options should return to the map page")
	var selected_before := _controller.model.selected_unit()
	_controller._on_tile_clicked(Vector2i(4, 1))
	if _controller.model.selected_unit() != null:
		_fail("Board clicks must not select while setup is visible")
	if _controller._handle_touch_tap(Vector2(500.0, 500.0)):
		_fail("Touch taps must not reach the board while setup is visible")
	if selected_before != null:
		_fail("Setup should clear any prior selection")


func _test_direct_load_map() -> void:
	_controller.set_mobile_mode(false)
	await process_frame
	if not _controller.load_map("borderlands"):
		_fail("Direct load_map should still start a match")
		return
	await process_frame
	if _controller.is_setup_visible() or _setup.visible:
		_fail("Direct load_map should hide setup")
	if _controller.current_config != null:
		_fail("Direct load_map should not create a production config")
	if _controller.model.local_player != PLAYER_1:
		_fail("Direct load_map should keep the legacy Player 1 view")
	if _controller.state.ply != 0 or _controller.state.active_player != PLAYER_1:
		_fail("Direct load_map should start a fresh Player 1 match")
	if not _desktop_hud.visible:
		_fail("Desktop HUD should be visible outside mobile mode")
	if _mobile_hud.visible:
		_fail("Mobile HUD should hide outside mobile mode")


func _test_invalid_start() -> void:
	var before := _controller.state
	var invalid := MatchConfig.new("missing_mode", "borderlands", PLAYER_1, PLAYER_1)
	if _controller.start_match(invalid):
		_fail("Invalid config must not start a match")
	if _controller.state != before:
		_fail("Invalid config must not replace the current match")
	if not _controller.start_match(MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_1)):
		_fail("A valid Player 1 / human-first match should start")
	if _controller.state.active_player != PLAYER_1:
		_fail("Valid config should set the first player")
	if not is_equal_approx(
		(_controller.get_node("CameraRig") as CameraRig).get_side_orientation_degrees(),
		0.0
	):
		_fail("Player 1 should use the default camera orientation")


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish() -> void:
	MobileMetrics.clear_dpi_override()
	print("Setup flow check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
