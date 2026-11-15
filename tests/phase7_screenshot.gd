extends SceneTree

const PORTRAIT_SIZE: Vector2i = Vector2i(1080, 2400)
const OVERVIEW_PATH: String = "user://phase7_overview.png"
const TACTICAL_PATH: String = "user://phase7_tactical.png"
const RECRUIT_PATH: String = "user://phase7_recruit.png"
const MENU_PATH: String = "user://phase7_menu.png"
const INFO_PATH: String = "user://phase7_info.png"


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	var viewport := SubViewport.new()
	viewport.size = PORTRAIT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene did not load")
		_finish(1)
		return
	var main := packed.instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	main.set_mobile_mode(true)
	if not main.load_map("borderlands"):
		_fail("Could not start the screenshot match")
		_finish(1)
		return
	var hud := main.get_node_or_null("UI/MobileHUD") as MobileHud
	if hud == null:
		_fail("Main has no mobile HUD")
		_finish(1)
		return
	hud.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	main._on_tile_clicked(Vector2i(4, 14))
	await process_frame
	await process_frame
	var error := await _save(viewport, OVERVIEW_PATH)
	main.state.add_gold(GameConfig.Player.PLAYER_1, 1)
	main._refresh_presentation(false)
	hud.open_recruit_sheet()
	await process_frame
	error = _merge_error(error, await _save(viewport, RECRUIT_PATH))
	hud.close_recruit_sheet()
	hud.open_menu()
	await process_frame
	error = _merge_error(error, await _save(viewport, MENU_PATH))
	hud.close_menu()
	var board := main.get_node_or_null("Board") as BoardView
	if board != null:
		main._on_touch_long_press(board.screen_position_for_tile(Vector2i(4, 14)))
		await process_frame
		error = _merge_error(error, await _save(viewport, INFO_PATH))
		main.handle_back_request()
	var rig := main.get_node_or_null("CameraRig") as CameraRig
	if rig != null:
		rig.toggle_mobile_view(BoardView.tile_to_world(Vector2i(8, 8), 0.0))
		await create_timer(0.5).timeout
		error = _merge_error(error, await _save(viewport, TACTICAL_PATH))
	MobileMetrics.clear_dpi_override()
	print("Phase 7 screenshots saved; error=%d" % error)
	_finish(error)


func _save(viewport: SubViewport, path: String) -> int:
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png(path)
	print("Saved %s (error %d)" % [path, error])
	return error


func _merge_error(current: int, next: int) -> int:
	return next if current == OK else current


func _fail(message: String) -> void:
	push_error(message)


func _finish(error: int) -> void:
	quit(0 if error == OK else 1)
