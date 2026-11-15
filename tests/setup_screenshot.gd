extends SceneTree

const PORTRAIT_SIZE: Vector2i = Vector2i(1080, 2400)
const MODE_PATH: String = "user://setup_mode.png"
const MAP_PATH: String = "user://setup_map.png"
const OPTIONS_PATH: String = "user://setup_options.png"


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
	var setup := main.get_node_or_null("UI/MatchSetup") as MatchSetup
	if setup == null:
		push_error("Main has no setup screen")
		quit(1)
		return
	setup.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	setup.show_setup()
	await process_frame
	await process_frame
	var error := await _save(viewport, MODE_PATH)
	setup.go_to_map_page()
	await process_frame
	await process_frame
	error = _merge_error(error, await _save(viewport, MAP_PATH))
	setup.go_to_options_page()
	setup.select_side(GameConfig.Player.PLAYER_2)
	setup.select_first_move(false)
	await process_frame
	await process_frame
	error = _merge_error(error, await _save(viewport, OPTIONS_PATH))
	MobileMetrics.clear_dpi_override()
	print("Setup screenshots saved; error=%d" % error)
	quit(0 if error == OK else 1)


func _save(viewport: SubViewport, path: String) -> int:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(path)
	print("Saved %s (error %d)" % [path, error])
	return error


func _merge_error(current: int, next: int) -> int:
	return current if current != OK else next
