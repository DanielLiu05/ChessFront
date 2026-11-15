extends SceneTree

const OUTPUT_PATH: String = "user://mobile_camera_screenshot.png"
const TACTICAL_OUTPUT_PATH: String = "user://mobile_camera_tactical.png"
const RECRUIT_OUTPUT_PATH: String = "user://mobile_recruit_sheet.png"
const MENU_OUTPUT_PATH: String = "user://mobile_menu.png"
const PORTRAIT_SIZE: Vector2i = Vector2i(1080, 2400)


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
	if main == null:
		push_error("Main is not a MatchController")
		quit(1)
		return
	main.set_mobile_mode(true)
	if not main.load_map("borderlands"):
		push_error("Could not start the mobile camera match")
		quit(1)
		return
	var mobile_hud := main.get_node_or_null("UI/MobileHUD") as MobileHud
	if mobile_hud != null:
		mobile_hud.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	main._on_tile_clicked(Vector2i(4, 14))
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	print("Mobile camera screenshot saved: %s (error %d)" % [OUTPUT_PATH, error])
	if mobile_hud != null:
		main.state.add_gold(GameConfig.Player.PLAYER_1, 1)
		main._refresh_presentation(false)
		mobile_hud.open_recruit_sheet()
		await process_frame
		await RenderingServer.frame_post_draw
		var recruit_error := viewport.get_texture().get_image().save_png(
			RECRUIT_OUTPUT_PATH
		)
		print(
			"Mobile recruit screenshot saved: %s (error %d)"
			% [RECRUIT_OUTPUT_PATH, recruit_error]
		)
		if recruit_error != OK:
			error = recruit_error
		mobile_hud.close_recruit_sheet()
		mobile_hud.open_menu()
		await process_frame
		await RenderingServer.frame_post_draw
		var menu_error := viewport.get_texture().get_image().save_png(MENU_OUTPUT_PATH)
		print(
			"Mobile menu screenshot saved: %s (error %d)"
			% [MENU_OUTPUT_PATH, menu_error]
		)
		if menu_error != OK:
			error = menu_error
		mobile_hud.close_menu()
	var rig := main.get_node_or_null("CameraRig") as CameraRig
	if rig != null:
		rig.toggle_mobile_view(BoardView.tile_to_world(Vector2i(8, 8), 0.0))
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var tactical_image := viewport.get_texture().get_image()
		var tactical_error := tactical_image.save_png(TACTICAL_OUTPUT_PATH)
		print(
			"Mobile tactical screenshot saved: %s (error %d)"
			% [TACTICAL_OUTPUT_PATH, tactical_error]
		)
		if tactical_error != OK:
			error = tactical_error
	MobileMetrics.clear_dpi_override()
	quit(0 if error == OK else 1)
