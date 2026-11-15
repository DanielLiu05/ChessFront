extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	var packed := load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		push_error("Main scene did not load")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080, 2400)
	root.add_child(viewport)
	var main := packed.instantiate() as MatchController
	viewport.add_child(main)
	await process_frame
	await process_frame
	if main == null:
		push_error("Main did not use MatchController")
		quit(1)
		return
	if main.is_mobile_mode():
		_failures += 1
		push_error("Desktop Main should not start in mobile mode")
	main.set_mobile_mode(true)
	if not main.load_map("borderlands"):
		_failures += 1
		push_error("Could not start the mobile input match")
		quit(1)
		return
	var board := main.get_node_or_null("Board") as BoardView
	var rig := main.get_node_or_null("CameraRig") as CameraRig
	var touch := main.get_node_or_null("TouchInput") as TouchInputAdapter
	var camera := main.get_node_or_null("CameraRig/Camera3D") as Camera3D
	if board == null or rig == null or touch == null or camera == null:
		_failures += 1
		push_error("Main is missing the mobile input or camera nodes")
		quit(1)
		return
	if not rig.mobile_mode:
		_failures += 1
		push_error("Camera should enter mobile mode")
	if not board.touch_input_enabled:
		_failures += 1
		push_error("Board should ignore emulated mouse in mobile mode")
	if not touch.enabled:
		_failures += 1
		push_error("Touch adapter should be enabled in mobile mode")
	if rig.get_mobile_tactical_distance() >= rig.get_mobile_overview_distance():
		_failures += 1
		push_error("Mobile zoom range should have a closer tactical distance")
	var emulated_click := InputEventMouseButton.new()
	emulated_click.device = InputEvent.DEVICE_ID_EMULATION
	emulated_click.button_index = MOUSE_BUTTON_LEFT
	emulated_click.pressed = true
	emulated_click.position = camera.unproject_position(
		BoardView.tile_to_world(Vector2i(4, 14), 0.0)
	)
	board._unhandled_input(emulated_click)
	if main.model.selected_unit() != null:
		_failures += 1
		push_error("Touch-emulated mouse must not select through the board")
	var fixed_pitch := rig.pitch_degrees
	var mobile_hud := main.get_node_or_null("UI/MobileHUD") as MobileHud
	if mobile_hud != null:
		mobile_hud.set_test_safe_insets(SafeInsets.new(0.0, 80.0, 0.0, 60.0))
	var focus_before := rig.target_focus
	touch._unhandled_input(_touch(0, Vector2(500.0, 300.0), true))
	touch._unhandled_input(_drag(0, Vector2(400.0, 300.0)))
	touch._unhandled_input(_touch(0, Vector2(400.0, 300.0), false))
	if rig.target_focus.is_equal_approx(focus_before):
		_failures += 1
		push_error("One-finger drag should pan the mobile camera")
	var distance_before := rig.target_distance
	touch._unhandled_input(_touch(0, Vector2(450.0, 300.0), true))
	touch._unhandled_input(_touch(1, Vector2(550.0, 300.0), true))
	touch._unhandled_input(_drag(1, Vector2(650.0, 300.0)))
	touch._unhandled_input(_touch(1, Vector2(650.0, 300.0), false))
	touch._unhandled_input(_touch(0, Vector2(450.0, 300.0), false))
	if is_equal_approx(rig.target_distance, distance_before):
		_failures += 1
		push_error("Pinch should change the mobile camera distance")
	if not is_zero_approx(rig.yaw_degrees):
		_failures += 1
		push_error("Mobile camera yaw should remain zero")
	if not is_equal_approx(rig.pitch_degrees, fixed_pitch):
		_failures += 1
		push_error("Mobile camera pitch should remain fixed")
	var screen := camera.unproject_position(BoardView.tile_to_world(Vector2i(8, 8), 0.0))
	var distance_before_double := rig.target_distance
	touch._unhandled_input(_touch(0, screen, true))
	touch._unhandled_input(_touch(0, screen, false))
	touch._unhandled_input(_touch(0, screen, true))
	touch._unhandled_input(_touch(0, screen, false))
	if is_equal_approx(rig.target_distance, distance_before_double):
		_failures += 1
		push_error("Double-tap should toggle the mobile camera zoom")
	if not is_zero_approx(rig.yaw_degrees) or not is_equal_approx(rig.pitch_degrees, fixed_pitch):
		_failures += 1
		push_error("Double-tap must not rotate the mobile camera")
	main.set_mobile_mode(false)
	if rig.mobile_mode or board.touch_input_enabled or touch.enabled:
		_failures += 1
		push_error("Disabling mobile mode should restore the desktop input path")
	print("Mobile input check complete: %d failure(s)" % _failures)
	quit(1 if _failures > 0 else 0)


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event
