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
		_fail("Could not start the mobile flow match")
		_finish()
		return
	_board = _main.get_node_or_null("Board") as BoardView
	_touch = _main.get_node_or_null("TouchInput") as TouchInputAdapter
	_hud = _main.get_node_or_null("UI/MobileHUD") as MobileHud
	if _board == null or _touch == null or _hud == null:
		_fail("Main is missing mobile board, touch or HUD nodes")
		_finish()
		return
	_hud.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	await process_frame
	await _test_tap_selection_and_move()
	await _test_selection_switch()
	await _test_44dp_snap_and_unhighlighted_tap()
	await _test_long_press_info()
	await _test_unexplored_info_card()
	await _test_gestures_do_not_mutate_state()
	await _test_back_stack()
	await _test_recruitment_sheet()
	await _test_draw_modal()
	await _test_menu_setup()
	_finish()


func _test_tap_selection_and_move() -> void:
	await _reset()
	var blocked := Vector2(_screen_for(Vector2i(4, 14)).x, 20.0)
	_tap(blocked)
	if _main.model.selected_unit() != null or _main.state.ply != 0:
		_fail("A touch in the unsafe top inset reached the board")
	_tap(_screen_for(Vector2i(4, 14)))
	var unit := _main.model.selected_unit()
	if unit == null or unit.tile != Vector2i(4, 14):
		_fail("Tap did not select the pawn")
		return
	_tap(_screen_for(Vector2i(4, 13)))
	_tap(_screen_for(Vector2i(4, 12)))
	await create_timer(0.5).timeout
	if _main.state.ply != 1 or _main.state.active_player != PLAYER_2:
		_fail("Tap-to-move did not consume exactly one ply")
	if _main.state.get_unit_at(Vector2i(4, 13)) == null:
		_fail("Pawn did not reach the tapped destination")


func _test_selection_switch() -> void:
	await _reset()
	_tap(_screen_for(Vector2i(4, 14)))
	_tap(_screen_for(Vector2i(5, 14)))
	var unit := _main.model.selected_unit()
	if unit == null or unit.tile != Vector2i(5, 14):
		_fail("Tapping another own unit did not switch selection")
	if _main.state.ply != 0:
		_fail("Switching selection changed the game state")


func _test_44dp_snap_and_unhighlighted_tap() -> void:
	await _reset()
	_tap(_screen_for(Vector2i(4, 14)))
	var destination := _screen_for(Vector2i(4, 13))
	var offset := Vector2(MobileMetrics.dp_to_ui(18.0, 420.0), 0.0)
	_tap(destination + offset)
	await create_timer(0.5).timeout
	if _main.state.ply != 1:
		_fail("A tap inside the 44dp destination hit area did not move")
	await _reset()
	_tap(_screen_for(Vector2i(4, 14)))
	_tap(_screen_for(Vector2i(8, 8)))
	await process_frame
	if _main.state.ply != 0:
		_fail("An unhighlighted tap committed a move")
	if _main.model.selected_unit() != null:
		_fail("Tap elsewhere did not clear the selection")


func _test_long_press_info() -> void:
	await _reset()
	var screen := _screen_for(Vector2i(4, 14))
	_send_touch(screen, true)
	await create_timer(0.45).timeout
	_send_touch(screen, false)
	if not _hud.is_info_card_open():
		_fail("Long press did not open the info card")
		return
	var title := _hud.find_child("InfoTitle", true, false) as Label
	var body := _hud.find_child("InfoBody", true, false) as Label
	if title == null or not title.text.contains("Pawn"):
		_fail("Info card title does not name the pawn")
	if body == null or not body.text.contains("Ground"):
		_fail("Info card body does not show known terrain")
	if not _main.handle_back_request() or _hud.is_info_card_open():
		_fail("Back did not close the info card")


func _test_gestures_do_not_mutate_state() -> void:
	await _reset()
	var center := _screen_for(Vector2i(8, 8))
	_send_touch(center, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = center + Vector2(120.0, 40.0)
	_touch._unhandled_input(drag)
	_send_touch(center + Vector2(120.0, 40.0), false)
	var second := center + Vector2(80.0, 0.0)
	_send_touch(center, true)
	_send_touch(second, true)
	var pinch := InputEventScreenDrag.new()
	pinch.index = 1
	pinch.position = second + Vector2(80.0, 0.0)
	_touch._unhandled_input(pinch)
	_send_touch(second + Vector2(80.0, 0.0), false)
	_send_touch(center, false)
	await process_frame
	if _main.state.ply != 0 or _main.state.active_player != PLAYER_1:
		_fail("Pan or pinch changed the game state")
	if _main.model.selected_unit() != null:
		_fail("Pan or pinch selected a unit")


func _test_unexplored_info_card() -> void:
	await _reset()
	_main._on_touch_long_press(_screen_for(Vector2i(0, 8)))
	if not _hud.is_info_card_open():
		_fail("Long press on an unexplored tile did not open the info card")
		return
	var body := _hud.find_child("InfoBody", true, false) as Label
	if body == null or not body.text.contains("Unexplored"):
		_fail("Unexplored tile info does not say Unexplored")
	if body != null and body.text.contains("Pawn"):
		_fail("Unexplored tile info leaked a unit")
	_main.handle_back_request()


func _test_back_stack() -> void:
	await _reset()
	_tap(_screen_for(Vector2i(4, 14)))
	_main._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	if _main.model.selected_unit() != null:
		_fail("Android back notification did not clear the selection")
	if _main.state.ply != 0:
		_fail("Android back notification changed the game state")
	_tap(_screen_for(Vector2i(4, 14)))
	if not _hud.open_menu():
		_fail("Menu did not open for the back-stack test")
		return
	if not _main.handle_back_request():
		_fail("Back did not consume the selection")
	if _main.model.selected_unit() != null:
		_fail("Back did not clear the selection")
	if not _hud.is_menu_open():
		_fail("Back closed the menu before clearing selection")
	if not _main.handle_back_request() or _hud.is_menu_open():
		_fail("Second back did not close the menu")
	if _main.handle_back_request():
		_fail("Back should be a no-op at the root")
	_main.model.pending_promotion_unit_id = _main.state.get_unit_at(Vector2i(4, 14)).id
	_main.model.pending_promotion_tile = Vector2i(4, 13)
	_main._refresh_presentation(false)
	if not _main.handle_back_request():
		_fail("Back did not consume the pending promotion")
	if _main.model.has_pending_promotion():
		_fail("Back did not cancel the pending promotion")
	await _reset()
	_main.state.add_gold(PLAYER_1, 1)
	_main._refresh_presentation(false)
	if not _main.model.begin_recruitment(UnitType.Type.PAWN):
		_fail("Could not enter recruitment mode for the back-stack test")
		_main.handle_back_request()
		return
	_main._refresh_presentation(false)
	if not _main.handle_back_request():
		_fail("Back did not consume recruitment mode")
	if _main.model.recruitment_type() != -1:
		_fail("Back did not cancel recruitment mode")


func _test_recruitment_sheet() -> void:
	await _reset()
	_main.state.add_gold(PLAYER_1, 1)
	_main._refresh_presentation(false)
	var recruit_button := _hud.find_child("RecruitButton", true, false) as Button
	if recruit_button == null or recruit_button.disabled:
		_fail("Recruit button is missing or disabled")
		return
	recruit_button.pressed.emit()
	await process_frame
	if not _hud.is_recruit_sheet_open():
		_fail("Recruit button did not open the bottom sheet")
		return
	var pawn_button := _hud._recruit_buttons.get(UnitType.Type.PAWN) as Button
	if pawn_button == null or pawn_button.disabled:
		_fail("Pawn recruitment is unavailable in the sheet")
		return
	pawn_button.pressed.emit()
	await process_frame
	if _main.model.recruitment_type() != UnitType.Type.PAWN:
		_fail("Choosing a unit did not enter spawn mode")
	if _hud.is_recruit_sheet_open():
		_fail("Recruit sheet stayed open after choosing a unit")
	if _main.model.recruitment_spawn_tiles.is_empty():
		_fail("Spawn mode has no highlighted tiles")
		return
	_tap(_screen_for(_main.model.recruitment_spawn_tiles[0]))
	await create_timer(0.5).timeout
	if _main.state.ply != 1 or _main.state.count_units_for_player(PLAYER_1) != 17:
		_fail("Tapping a spawn tile did not recruit a unit")


func _test_draw_modal() -> void:
	await _reset()
	DrawSystem.offer_draw(_main.state, PLAYER_2)
	_main._refresh_presentation(false)
	if not _hud.is_draw_modal_open():
		_fail("Incoming draw offer did not open the draw modal")
		return
	var decline := _hud.find_child("DrawDeclineButton", true, false) as Button
	decline.pressed.emit()
	await process_frame
	if _main.state.draw_offered_by != GameConfig.NO_PLAYER or _main.state.ply != 0:
		_fail("Declining a draw should clear the offer without a turn")
	DrawSystem.offer_draw(_main.state, PLAYER_2)
	_main._refresh_presentation(false)
	var accept := _hud.find_child("DrawAcceptButton", true, false) as Button
	accept.pressed.emit()
	await process_frame
	if not _main.state.game_over or _main.state.draw_reason != DrawSystem.REASON_AGREEMENT:
		_fail("Accepting a draw did not end the game by agreement")
	if not _hud.is_game_over_visible():
		_fail("Game-over overlay did not appear after a draw")


func _test_menu_setup() -> void:
	await _reset()
	_tap(_screen_for(Vector2i(4, 14)))
	_tap(_screen_for(Vector2i(4, 13)))
	await create_timer(0.5).timeout
	if _main.state.ply != 1:
		_fail("Could not create an in-progress match for the setup test")
		return
	if not _hud.open_menu():
		_fail("Menu did not open for Return to Setup")
		return
	var setup_button := _hud.find_child("MenuSetupButton", true, false) as Button
	if setup_button == null:
		_fail("Menu is missing Return to Setup")
		return
	setup_button.pressed.emit()
	await process_frame
	if not _main.handle_back_request():
		_fail("Back did not close the Return to Setup confirmation")
	if not _hud.is_menu_open():
		_fail("Back closed the whole menu instead of the confirmation")
	setup_button.pressed.emit()
	await process_frame
	var confirm := _hud.find_child("ConfirmSetupButton", true, false) as Button
	if confirm == null:
		_fail("Return to Setup confirmation is missing")
		return
	confirm.pressed.emit()
	await process_frame
	if not _main.is_setup_visible():
		_fail("Confirming Return to Setup did not open setup")
	if _hud.visible:
		_fail("Mobile HUD stayed visible behind setup")
	if _main.state.ply != 1:
		_fail("Return to Setup should leave the current match in memory")


func _reset() -> void:
	_touch.cancel_gesture()
	_hud.close_top_modal()
	if _main.state != null and _main.state.game_over:
		_main.load_map("borderlands")
	else:
		_main.load_map("borderlands")
	await process_frame
	await process_frame


func _tap(screen: Vector2) -> void:
	_send_touch(screen, true)
	_send_touch(screen, false)


func _send_touch(screen: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = screen
	event.pressed = pressed
	_touch._unhandled_input(event)


func _screen_for(tile: Vector2i) -> Vector2:
	return _board.screen_position_for_tile(tile)


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish() -> void:
	MobileMetrics.clear_dpi_override()
	print("Mobile flow check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)
