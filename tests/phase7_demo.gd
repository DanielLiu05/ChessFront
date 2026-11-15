extends SceneTree

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2

var _failures: int = 0
var _viewport: SubViewport
var _main: MatchController
var _board: BoardView
var _touch: TouchInputAdapter
var _hud: MobileHud


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1080, 2400)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene did not load")
		_finish()
		return
	_main = packed.instantiate() as MatchController
	_viewport.add_child(_main)
	await process_frame
	await process_frame
	_main.set_mobile_mode(true)
	if not _main.load_map("borderlands"):
		_fail("Could not start the Phase 7 demo match")
		_finish()
		return
	_board = _main.get_node_or_null("Board") as BoardView
	_touch = _main.get_node_or_null("TouchInput") as TouchInputAdapter
	_hud = _main.get_node_or_null("UI/MobileHUD") as MobileHud
	if _board == null or _touch == null or _hud == null:
		_fail("Missing mobile board, touch or HUD")
		_finish()
		return
	_hud.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	await process_frame
	await _select_and_move()
	await _recruit()
	await _long_press_info()
	_camera_views()
	await _draw_and_back()
	_finish()


func _select_and_move() -> void:
	await _reset()
	_tap(Vector2i(4, 14))
	var unit := _main.model.selected_unit()
	if unit == null:
		_fail("Pawn selection failed")
		return
	print(
		"Selected %s; %d destinations."
		% [unit.definition().display_name, _main.model.legal_destinations.size()]
	)
	_tap(Vector2i(4, 13))
	await create_timer(0.5).timeout
	if _main.state.ply != 1 or _main.state.active_player != PLAYER_2:
		_fail("Tap move did not advance the turn")
	var reply_model := PresentationModel.new(_main.state, PLAYER_2)
	reply_model.select_unit_at(Vector2i(4, 1))
	if reply_model.legal_destinations.is_empty():
		_fail("Player 2 has no scripted reply")
		return
	var reply := reply_model.move_selected_to(reply_model.legal_destinations[0])
	if not reply.success:
		_fail("Player 2 reply failed")
		return
	_main.model.refresh()
	_main._refresh_presentation(true)
	print("Scripted reply; active=P%d ply=%d." % [int(_main.state.active_player), _main.state.ply])
	print(
		"Known: explored=%d visible=%d units=%d."
		% [
			_main.model.view.knowledge.explored_tiles().size(),
			_main.model.view.knowledge.visible_tiles().size(),
			_main.model.view.get_known_units().size(),
		]
	)


func _recruit() -> void:
	await _reset()
	_main.state.add_gold(PLAYER_1, 1)
	_main._refresh_presentation(false)
	var recruit := _hud.find_child("RecruitButton", true, false) as Button
	recruit.pressed.emit()
	await process_frame
	if not _hud.is_recruit_sheet_open():
		_fail("Recruit sheet did not open")
		return
	var pawn := _hud.find_child("RecruitUnit_%d" % UnitType.Type.PAWN, true, false) as Button
	pawn.pressed.emit()
	await process_frame
	if _main.model.recruitment_spawn_tiles.is_empty():
		_fail("No spawn highlights")
		return
	_tap(_main.model.recruitment_spawn_tiles[0])
	await create_timer(0.5).timeout
	if _main.state.ply != 1:
		_fail("Recruitment did not consume the turn")
	print("Recruited Pawn; active=P%d." % int(_main.state.active_player))


func _long_press_info() -> void:
	_main.load_map("borderlands")
	await process_frame
	_main._on_touch_long_press(_board.screen_position_for_tile(Vector2i(4, 14)))
	if not _hud.is_info_card_open():
		_fail("Long press did not open the info card")
		return
	var body := _hud.find_child("InfoBody", true, false) as Label
	if body == null or not body.text.contains("Pawn"):
		_fail("Info card does not show the pawn")
	print("Info card opened for the pawn.")
	_main.handle_back_request()


func _camera_views() -> void:
	var rig := _main.get_node_or_null("CameraRig") as CameraRig
	if rig == null:
		_fail("Missing camera rig")
		return
	var overview := rig.get_mobile_overview_distance()
	var tactical := rig.get_mobile_tactical_distance()
	rig.toggle_mobile_view(Vector3.ZERO)
	print("Tactical distance %.1f; overview %.1f." % [tactical, overview])
	if not is_equal_approx(rig.target_distance, tactical):
		_fail("Double-tap camera did not enter tactical distance")
	rig.toggle_mobile_view(Vector3.ZERO)
	if not is_equal_approx(rig.target_distance, overview):
		_fail("Second double-tap did not return to overview")


func _draw_and_back() -> void:
	_main.load_map("borderlands")
	await process_frame
	DrawSystem.offer_draw(_main.state, PLAYER_2)
	_main._refresh_presentation(false)
	if not _hud.is_draw_modal_open():
		_fail("Draw modal did not open")
		return
	var accept := _hud.find_child("DrawAcceptButton", true, false) as Button
	accept.pressed.emit()
	await process_frame
	if not _main.state.game_over or _main.state.draw_reason != DrawSystem.REASON_AGREEMENT:
		_fail("Draw agreement did not end the game")
	print("Draw by agreement; game over.")
	_main.load_map("borderlands")
	await process_frame
	_tap(Vector2i(4, 14))
	_hud.open_menu()
	if not _main.handle_back_request():
		_fail("Back did not consume selection")
	if _main.model.selected_unit() != null:
		_fail("Back did not clear selection")
	if not _main.handle_back_request() or _hud.is_menu_open():
		_fail("Second back did not close the menu")
	print("Back stack: selection, then menu.")


func _reset() -> void:
	_touch.cancel_gesture()
	_main.load_map("borderlands")
	await process_frame
	await process_frame


func _tap(tile: Vector2i) -> void:
	var screen := _board.screen_position_for_tile(tile)
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = screen
	down.pressed = true
	_touch._unhandled_input(down)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = screen
	up.pressed = false
	_touch._unhandled_input(up)


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish() -> void:
	MobileMetrics.clear_dpi_override()
	print("Phase 7 demo complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
