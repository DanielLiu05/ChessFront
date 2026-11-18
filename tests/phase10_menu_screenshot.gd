extends SceneTree

const MOBILE_SIZE: Vector2i = Vector2i(1080, 2400)
const DESKTOP_SIZE: Vector2i = Vector2i(1440, 900)

var _error: int = OK


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	await _capture_mobile()
	MobileMetrics.set_dpi_override(160.0)
	await _capture_desktop()
	MobileMetrics.clear_dpi_override()
	print("Phase 10 menu screenshots saved; error=%d" % _error)
	quit(0 if _error == OK else 1)


func _capture_mobile() -> void:
	var viewport := SubViewport.new()
	viewport.size = MOBILE_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main := (load("res://scenes/main/Main.tscn") as PackedScene).instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	main.set_mobile_mode(true)
	var setup := main.get_node_or_null("UI/MatchSetup") as MatchSetup
	if setup == null:
		_error = FAILED
		viewport.free()
		return
	setup.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	setup.show_setup()
	await _settle()
	_error = _merge(_error, await _save(viewport, "user://phase10_setup_mode.png"))
	setup.go_to_map_page()
	await _settle()
	_error = _merge(_error, await _save(viewport, "user://phase10_setup_map.png"))
	setup.go_to_options_page()
	await _settle()
	_error = _merge(_error, await _save(viewport, "user://phase10_setup_options.png"))

	if not main.start_match(MatchConfig.new("vs_ai", "borderlands", 1, 1)):
		_error = FAILED
		viewport.free()
		return
	await _settle()
	main.set_paused(true)
	await _settle()
	_error = _merge(_error, await _save(viewport, "user://phase10_pause.png"))
	main._on_settings_requested()
	await _settle()
	_error = _merge(_error, await _save(viewport, "user://phase10_settings.png"))
	main.settings_panel().handle_back()
	main.set_paused(false)
	await _settle()

	main.model.stats.captures = 2
	main.model.stats.gold_earned = 4
	main.model.stats.scouts_lost = 1
	var mine := main.state.gold_mines[0]
	var pawn := main.state.get_unit_at(Vector2i(4, 14))
	if pawn != null:
		MovementTestUtils.relocate_unit(main.state, pawn, mine.tile)
	main.state.game_over = true
	main.state.winner = 1
	main._refresh_presentation(true)
	await _settle()
	_error = _merge(_error, await _save(viewport, "user://phase10_game_over.png"))
	viewport.free()


func _capture_desktop() -> void:
	var viewport := SubViewport.new()
	viewport.size = DESKTOP_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main := (load("res://scenes/main/Main.tscn") as PackedScene).instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	var setup := main.get_node_or_null("UI/MatchSetup") as MatchSetup
	if setup != null:
		setup.show_setup()
		setup.go_to_map_page()
		await _settle()
		_error = _merge(_error, await _save(viewport, "user://phase10_desktop_setup.png"))
	if not main.start_match(MatchConfig.new("vs_ai", "borderlands", 1, 1)):
		_error = FAILED
		viewport.free()
		return
	await _settle()
	main.set_paused(true)
	await _settle()
	_error = _merge(_error, await _save(viewport, "user://phase10_desktop_pause.png"))
	main._on_settings_requested()
	await _settle()
	_error = _merge(_error, await _save(viewport, "user://phase10_desktop_settings.png"))
	main.settings_panel().handle_back()
	main.set_paused(false)
	await _settle()
	main.model.stats.captures = 3
	main.model.stats.gold_earned = 7
	main.model.stats.scouts_lost = 1
	main.state.game_over = true
	main.state.winner = 2
	main._refresh_presentation(false)
	await _settle()
	_error = _merge(_error, await _save(viewport, "user://phase10_desktop_game_over.png"))
	viewport.free()


func _settle() -> void:
	await process_frame
	await process_frame
	await process_frame


func _save(viewport: SubViewport, path: String) -> int:
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var error := image.save_png(path)
	print("Saved %s (error %d)" % [path, error])
	return error


func _merge(current: int, next: int) -> int:
	return current if current != OK else next
