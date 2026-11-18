extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	PlatformMode.set_test_overrides(-1, 1, 0)
	MobileMetrics.clear_dpi_override()
	WebViewport.set_test_pixel_ratio(1.0)
	await _check_setup(Vector2i(1280, 720), SafeInsets.zero(), "web desktop")
	WebViewport.set_test_pixel_ratio(2.0)
	var mobile_insets := SafeInsets.new(0.0, 88.0, 0.0, 68.0)
	await _check_setup(Vector2i(780, 1688), mobile_insets, "web mobile")
	await _check_mobile_hud(Vector2i(780, 1688), mobile_insets)
	WebViewport.clear_test_pixel_ratio()
	PlatformMode.clear_test_overrides()
	print("Web layout check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _check_setup(size: Vector2i, insets: SafeInsets, label: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	root.add_child(viewport)
	var setup := (load("res://scenes/ui/MatchSetup.tscn") as PackedScene).instantiate() as MatchSetup
	viewport.add_child(setup)
	await process_frame
	await process_frame
	setup.set_test_safe_insets(insets)
	setup.show_setup(null)
	await process_frame
	await process_frame
	var panel := setup.find_child("SetupPanel", true, false) as Control
	if panel == null:
		_fail("%s: setup panel missing" % label)
	else:
		if panel.size.x < 300.0:
			_fail("%s: setup panel is too narrow: %.1f" % [label, panel.size.x])
		if label == "web desktop" and panel.size.x < 500.0:
			_fail("%s: desktop setup panel should be at least 500px, got %.1f" % [label, panel.size.x])
		if label == "web mobile" and panel.size.x < 600.0:
			_fail("%s: mobile setup panel is too narrow: %.1f" % [label, panel.size.x])
		if label == "web mobile" and panel.size.x > float(size.x):
			_fail("%s: mobile setup panel overflows width" % label)
	_check_buttons(setup, size, insets, label)
	setup.go_to_options_page()
	await process_frame
	await process_frame
	_check_buttons(setup, size, insets, label + " options")
	var primary := setup.find_child("SetupPrimaryButton", true, false) as Button
	if primary == null or primary.size.y < 44.0:
		_fail("%s: primary action is under 44px" % label)
	viewport.free()


func _check_mobile_hud(size: Vector2i, insets: SafeInsets) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	root.add_child(viewport)
	var hud := (load("res://scenes/ui/MobileHUD.tscn") as PackedScene).instantiate() as MobileHud
	viewport.add_child(hud)
	await process_frame
	await process_frame
	hud.set_test_safe_insets(insets)
	var loaded := MapLibrary.load_by_id("borderlands")
	if not loaded.is_valid():
		_fail("Could not load borderlands for the web mobile HUD")
		viewport.free()
		return
	var state := GameState.new(loaded.map)
	var model := PresentationModel.new(state, GameConfig.Player.PLAYER_1)
	model.ai_player = GameConfig.Player.PLAYER_2
	hud.refresh(model)
	await process_frame
	await process_frame
	_check_buttons(hud, size, insets, "web mobile HUD")
	viewport.free()


func _check_buttons(
	root_control: Control,
	size: Vector2i,
	insets: SafeInsets,
	label: String
) -> void:
	var safe := Rect2(
		Vector2(insets.left, insets.top),
		Vector2(
			size.x - insets.left - insets.right,
			size.y - insets.top - insets.bottom
		)
	)
	var minimum := MobileMetrics.touch_target_ui()
	var buttons := 0
	for node: Node in root_control.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null or not button.is_visible_in_tree() or button.disabled:
			continue
		buttons += 1
		var rect := button.get_global_rect()
		if not safe.encloses(rect):
			_fail("%s: button %s is outside the safe area: %s" % [label, button.name, str(rect)])
		if rect.size.y < minimum - 1.0:
			_fail(
				"%s: button %s is under %.1fpx: %.1f"
				% [label, button.name, minimum, rect.size.y]
			)
	if buttons == 0:
		_fail("%s: no enabled buttons found" % label)


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)
