extends SceneTree

const PORTRAIT_SIZE: Vector2i = Vector2i(1080, 2400)
const GAME_OVER_PATH: String = "user://lifecycle_game_over.png"
const MENU_PATH: String = "user://lifecycle_menu.png"


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	var viewport := SubViewport.new()
	viewport.size = PORTRAIT_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene did not load")
		quit(1)
		return
	var main := packed.instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	main.set_mobile_mode(true)
	if not main.start_match(
		MatchConfig.new(
			"vs_ai", "borderlands", GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_1
		)
	):
		push_error("Could not start the lifecycle screenshot match")
		quit(1)
		return
	var hud := main.get_node_or_null("UI/MobileHUD") as MobileHud
	if hud == null:
		push_error("Main has no mobile HUD")
		quit(1)
		return
	hud.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	main.state.game_over = true
	main.state.winner = GameConfig.Player.PLAYER_2
	main._refresh_presentation(false)
	await process_frame
	await process_frame
	var error := await _save(viewport, GAME_OVER_PATH)
	if not main.rematch():
		push_error("Could not rematch for the menu screenshot")
		quit(1)
		return
	await process_frame
	hud.open_menu()
	await process_frame
	await process_frame
	error = _merge_error(error, await _save(viewport, MENU_PATH))
	MobileMetrics.clear_dpi_override()
	print("Lifecycle screenshots saved; error=%d" % error)
	quit(0 if error == OK else 1)


func _save(viewport: SubViewport, path: String) -> int:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(path)
	print("Saved %s (error %d)" % [path, error])
	return error


func _merge_error(current: int, next: int) -> int:
	return current if current != OK else next
