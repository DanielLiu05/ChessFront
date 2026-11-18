extends SceneTree

const FACTOR: float = 1.5
const MOBILE_SIZES: Array[Vector2i] = [
	Vector2i(720, 1600),
	Vector2i(1080, 2400),
]

var _failures: int = 0


func _initialize() -> void:
	MobileMetrics.set_dpi_override(420.0)
	for size: Vector2i in MOBILE_SIZES:
		await _check_mobile(size)
	MobileMetrics.set_dpi_override(160.0)
	await _check_desktop(Vector2i(1152, 648))
	MobileMetrics.clear_dpi_override()
	print("Text scale layout check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _check_mobile(size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main := (load("res://scenes/main/Main.tscn") as PackedScene).instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	var insets := SafeInsets.new(8.0, 40.0, 8.0, 36.0)
	main.set_mobile_mode(true)
	var setup := main.get_node_or_null("UI/MatchSetup") as MatchSetup
	if setup == null:
		_fail("No setup screen at %s" % str(size))
		viewport.free()
		return
	setup.set_test_safe_insets(insets)
	main._presentation_config.set_text_scale(150)
	main._apply_text_scale()
	await process_frame
	setup.show_setup(null)
	await process_frame
	await process_frame
	_check_setup_page(setup, size, "mode")
	setup.go_to_map_page()
	await process_frame
	await process_frame
	_check_setup_page(setup, size, "map")
	setup.go_to_options_page()
	await process_frame
	await process_frame
	_check_setup_page(setup, size, "options")

	if not main.start_match(MatchConfig.new("vs_ai", "borderlands", 1, 1)):
		_fail("Could not start the text-scale match at %s" % str(size))
		viewport.free()
		return
	main._apply_text_scale()
	await process_frame
	await process_frame
	var mobile_hud := main.get_node_or_null("UI/MobileHUD") as MobileHud
	if mobile_hud == null:
		_fail("No mobile HUD at %s" % str(size))
	else:
		_check_controls(mobile_hud, Rect2(Vector2.ZERO, Vector2(size)), "mobile HUD")
		main.state.game_over = true
		main.state.winner = GameConfig.Player.PLAYER_1
		main._refresh_presentation(false)
		await process_frame
		await process_frame
		_check_controls(mobile_hud, Rect2(Vector2.ZERO, Vector2(size)), "mobile game over")
		main.state.game_over = false
		main.state.winner = GameConfig.NO_PLAYER
		main._refresh_presentation(false)
	main.set_paused(true)
	await process_frame
	await process_frame
	var pause := main.pause_menu()
	_check_controls(pause, Rect2(Vector2.ZERO, Vector2(size)), "pause menu")
	main._on_settings_requested()
	await process_frame
	await process_frame
	var settings := main.settings_panel()
	_check_controls(settings, Rect2(Vector2.ZERO, Vector2(size)), "settings")
	settings.handle_back()
	main.set_paused(false)
	await process_frame
	viewport.free()


func _check_desktop(size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var main := (load("res://scenes/main/Main.tscn") as PackedScene).instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	main._presentation_config.set_text_scale(150)
	main._apply_text_scale()
	await process_frame
	var setup := main.get_node_or_null("UI/MatchSetup") as MatchSetup
	if setup != null:
		setup.show_setup(null)
		await process_frame
		_check_setup_page(setup, size, "desktop mode")
		setup.go_to_map_page()
		await process_frame
		_check_setup_page(setup, size, "desktop map")
		setup.go_to_options_page()
		await process_frame
		_check_setup_page(setup, size, "desktop options")
	if not main.start_match(MatchConfig.new("vs_ai", "borderlands", 1, 1)):
		_fail("Could not start the desktop text-scale match")
		viewport.free()
		return
	main._apply_text_scale()
	await process_frame
	await process_frame
	var hud := main.get_node_or_null("UI/HUD") as MatchHud
	if hud != null:
		_check_controls(hud, Rect2(Vector2.ZERO, Vector2(size)), "desktop HUD")
		var top_bar := hud.find_child("TopBar", true, false) as Control
		for rail_name: String in ["LeftRail", "RightRail"]:
			var rail := hud.find_child(rail_name, true, false) as Control
			if top_bar != null and rail != null \
					and top_bar.get_global_rect().end.y > rail.get_global_rect().position.y + 0.5:
				_fail("%s overlaps the top bar at %s" % [rail_name, str(size)])
		main.state.game_over = true
		main.state.winner = GameConfig.Player.PLAYER_1
		main._refresh_presentation(false)
		await process_frame
		await process_frame
		_check_controls(hud, Rect2(Vector2.ZERO, Vector2(size)), "desktop game over")
		main.state.game_over = false
		main.state.winner = GameConfig.NO_PLAYER
		main._refresh_presentation(false)
	main.set_paused(true)
	await process_frame
	await process_frame
	_check_controls(main.pause_menu(), Rect2(Vector2.ZERO, Vector2(size)), "desktop pause")
	main._on_settings_requested()
	await process_frame
	await process_frame
	_check_controls(main.settings_panel(), Rect2(Vector2.ZERO, Vector2(size)), "desktop settings")
	main.settings_panel().handle_back()
	main.set_paused(false)
	await process_frame
	viewport.free()


func _check_setup_page(setup: MatchSetup, size: Vector2i, name: String) -> void:
	var screen := Rect2(Vector2.ZERO, Vector2(size))
	for node: Node in setup.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		if control is SafeAreaContainer:
			continue
		var scroll := _scroll_ancestor(control)
		if scroll != null:
			var scroll_rect := scroll.get_global_rect()
			if control.get_global_rect().position.x < scroll_rect.position.x - 1.0 \
					or control.get_global_rect().end.x > scroll_rect.end.x + 1.0:
				_fail("%s: %s is clipped horizontally at %s" % [name, control.name, str(size)])
			if scroll.get_h_scroll_bar().visible:
				_fail("%s: horizontal scrollbar at %s" % [name, str(size)])
			continue
		if not screen.encloses(control.get_global_rect()):
			_fail(
				"%s: %s is off-screen at %s: %s"
				% [name, control.name, str(size), str(control.get_global_rect())]
			)
	for node: Node in setup.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.is_visible_in_tree():
			_check_button(button, screen, name, size)


func _check_controls(root_control: Control, screen: Rect2, name: String) -> void:
	if root_control == null:
		_fail("%s is missing" % name)
		return
	if not root_control.is_visible_in_tree():
		_fail("%s is not visible" % name)
		return
	for node: Node in root_control.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		if control is SafeAreaContainer:
			continue
		var scroll := _scroll_ancestor(control, root_control)
		if scroll != null:
			var scroll_rect := scroll.get_global_rect()
			var rect := control.get_global_rect()
			if rect.position.x < scroll_rect.position.x - 1.0 \
					or rect.end.x > scroll_rect.end.x + 1.0:
				_fail("%s: %s is clipped horizontally" % [name, control.name])
			continue
		var rect := control.get_global_rect()
		if not screen.encloses(rect):
			_fail("%s: %s is off-screen: %s" % [name, control.name, str(rect)])
	for node: Node in root_control.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.is_visible_in_tree():
			_check_button(button, screen, name, Vector2i(screen.size))


func _check_button(button: Button, screen: Rect2, name: String, size: Vector2i) -> void:
	var rect := button.get_global_rect()
	if rect.size.y < MobileMetrics.touch_target_ui() - 1.0:
		_fail(
			"%s: %s is shorter than 44dp at %s: %.1f"
			% [name, button.name, str(size), rect.size.y]
		)
	if not screen.encloses(rect):
		var scroll := _scroll_ancestor(button)
		if scroll == null:
			_fail("%s: button %s is off-screen at %s" % [name, button.name, str(size)])


func _scroll_ancestor(control: Control, stopper: Control = null) -> ScrollContainer:
	var node := control.get_parent()
	while node != null and node != stopper:
		if node is ScrollContainer:
			return node as ScrollContainer
		node = node.get_parent()
	return null


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)
