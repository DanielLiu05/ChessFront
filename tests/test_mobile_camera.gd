extends TestCase


func test_mobile_mode_locks_yaw_and_pitch() -> bool:
	var rig := _rig()
	rig.set_mobile_mode(true)
	var fixed_pitch := rig.pitch_degrees
	rig.rotate_by(90.0, 20.0)
	assert_eq(rig.yaw_degrees, 0.0, "mobile yaw stays locked")
	assert_eq(rig.pitch_degrees, fixed_pitch, "mobile pitch stays fixed")
	rig.mobile_pan_by(Vector2(120.0, -80.0))
	rig.mobile_pinch(1.3)
	assert_eq(rig.yaw_degrees, 0.0, "pan and pinch do not rotate yaw")
	assert_eq(rig.pitch_degrees, fixed_pitch, "pan and pinch do not rotate pitch")
	rig.free()
	return true


func test_mobile_side_orientation_flips_and_stays_locked() -> bool:
	var rig := _rig()
	rig.set_mobile_mode(true)
	rig.set_side_orientation(GameConfig.Player.PLAYER_2)
	assert_eq(rig.get_side_orientation_degrees(), 180.0, "player 2 side orientation")
	assert_eq(rig.yaw_degrees, 180.0, "mobile yaw matches player 2")
	var fixed_pitch := rig.pitch_degrees
	rig.rotate_by(90.0, 20.0)
	rig.mobile_pan_by(Vector2(120.0, -80.0))
	rig.mobile_pinch(1.3)
	assert_eq(rig.yaw_degrees, 180.0, "gestures do not rotate the flipped side")
	assert_eq(rig.pitch_degrees, fixed_pitch, "flipped side keeps the fixed pitch")
	rig.reset_view()
	assert_eq(rig.yaw_degrees, 180.0, "reset keeps the player 2 side")
	rig.set_side_orientation(GameConfig.Player.PLAYER_1)
	assert_eq(rig.yaw_degrees, 0.0, "player 1 side returns to default yaw")
	rig.free()
	return true


func test_desktop_side_orientation_and_reset() -> bool:
	var rig := _rig()
	rig.set_side_orientation(GameConfig.Player.PLAYER_2)
	assert_eq(rig.yaw_degrees, 180.0, "desktop starts on the player 2 side")
	rig.rotate_by(30.0, 0.0)
	assert_eq(rig.yaw_degrees, 210.0, "desktop can still rotate from the flipped side")
	rig.reset_view()
	assert_eq(rig.yaw_degrees, 180.0, "desktop reset returns to the local side")
	rig.free()
	return true


func test_mobile_zoom_limits() -> bool:
	var rig := _rig()
	rig.set_mobile_mode(true)
	var overview := rig.get_mobile_overview_distance()
	var tactical := rig.get_mobile_tactical_distance()
	assert_true(tactical < overview, "tactical distance is closer than overview")
	assert_true(
		is_equal_approx(rig.target_distance, overview),
		"mobile mode starts at the overview"
	)
	for _index in 20:
		rig.mobile_pinch(2.0)
	assert_true(
		rig.target_distance >= tactical - 0.001,
		"pinch in clamps at the tactical limit"
	)
	for _index in 20:
		rig.mobile_pinch(0.5)
	assert_true(
		rig.target_distance <= overview + 0.001,
		"pinch out clamps at the overview limit"
	)
	rig.free()
	return true


func test_mobile_pan_clamped_to_board() -> bool:
	var rig := _rig()
	rig.set_mobile_mode(true)
	rig.mobile_pan_by(Vector2(100000.0, 100000.0))
	var bounds := rig.get_mobile_focus_bounds()
	assert_true(rig.target_focus.x <= bounds.end.x + 0.001, "pan clamps x maximum")
	assert_true(rig.target_focus.z <= bounds.end.y + 0.001, "pan clamps z maximum")
	rig.mobile_pan_by(Vector2(-200000.0, -200000.0))
	assert_true(rig.target_focus.x >= bounds.position.x - 0.001, "pan clamps x minimum")
	assert_true(rig.target_focus.z >= bounds.position.y - 0.001, "pan clamps z minimum")
	rig.free()
	return true


func test_double_tap_toggles_overview_and_tactical() -> bool:
	var rig := _rig()
	rig.set_mobile_mode(true)
	var overview := rig.get_mobile_overview_distance()
	var tactical := rig.get_mobile_tactical_distance()
	assert_true(rig.is_mobile_overview(), "mobile starts in overview")
	rig.toggle_mobile_view(Vector3(2.0, 0.0, -3.0))
	assert_true(
		is_equal_approx(rig.target_distance, tactical),
		"double-tap zooms to tactical"
	)
	assert_true(
		rig.target_focus.distance_to(Vector3(2.0, 0.0, -3.0)) < 0.001,
		"tactical zoom centers on the tapped tile"
	)
	assert_false(rig.is_mobile_overview(), "camera reports tactical mode")
	rig.toggle_mobile_view(Vector3(2.0, 0.0, -3.0))
	assert_true(
		is_equal_approx(rig.target_distance, overview),
		"second double-tap returns to overview"
	)
	assert_true(
		rig.target_focus.distance_to(Vector3.ZERO) < 0.001,
		"overview centers on the board"
	)
	rig.free()
	return true


func test_overview_and_tactical_framing_fit() -> bool:
	var rig := _rig()
	rig.set_mobile_mode(true)
	var viewport_size := rig.get_mobile_viewport_size()
	var aspect := viewport_size.x / viewport_size.y
	var tan_v := tan(deg_to_rad(rig.camera.fov * 0.5))
	var tan_h := tan_v * aspect
	assert_true(
		rig._framing_fits(
			_board_points(rig.mobile_board_bounds, 0.0),
			rig.get_mobile_overview_distance(),
			0.9,
			tan_h,
			tan_v
		),
		"overview frames the whole playable board"
	)
	assert_true(
		rig._framing_fits(
			_board_points(Rect2(Vector2(-4.0, -4.0), Vector2(8.0, 8.0)), 0.0),
			rig.get_mobile_tactical_distance(),
			0.85,
			tan_h,
			tan_v
		),
		"tactical framing fits about eight columns"
	)
	rig.free()
	return true


func test_mobile_limits_recalculate_with_viewport() -> bool:
	var rig := _rig(Vector2(720.0, 1600.0))
	rig.set_mobile_mode(true)
	var first_overview := rig.get_mobile_overview_distance()
	var first_tactical := rig.get_mobile_tactical_distance()
	rig.set_mobile_viewport_size(Vector2(1200.0, 1800.0))
	var second_overview := rig.get_mobile_overview_distance()
	var second_tactical := rig.get_mobile_tactical_distance()
	assert_true(
		not is_equal_approx(first_overview, second_overview),
		"overview distance follows the viewport"
	)
	assert_true(second_tactical < second_overview, "tactical remains closer")
	assert_true(first_tactical < first_overview, "first viewport keeps the range")
	rig.free()
	return true


func test_mobile_board_bounds_define_pan_area() -> bool:
	var rig := _rig()
	rig.set_mobile_board_bounds(Rect2(Vector2(-8.0, -8.0), Vector2(16.0, 16.0)))
	assert_eq(
		rig.get_mobile_focus_bounds(),
		Rect2(Vector2(-9.0, -9.0), Vector2(18.0, 18.0)),
		"pan bounds include a one-tile margin"
	)
	rig.free()
	return true


func test_desktop_camera_remains_unchanged() -> bool:
	var rig := _rig()
	assert_false(rig.mobile_mode, "desktop starts outside mobile mode")
	rig.rotate_by(30.0, 10.0)
	assert_eq(rig.yaw_degrees, 30.0, "desktop yaw still rotates")
	assert_eq(rig.pitch_degrees, 62.0, "desktop pitch still rotates")
	rig.zoom_by(100.0)
	assert_eq(rig.target_distance, 30.0, "desktop zoom clamps at 30")
	rig.zoom_by(-100.0)
	assert_eq(rig.target_distance, 8.0, "desktop zoom clamps at 8")
	rig.free()
	return true


func test_desktop_mouse_ignored_in_mobile_mode() -> bool:
	var rig := _rig()
	rig.set_mobile_mode(true)
	var before := rig.target_focus
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	rig._unhandled_input(wheel)
	assert_eq(rig.target_focus, before, "mobile mode ignores desktop mouse input")
	assert_eq(rig.yaw_degrees, 0.0, "mobile mode keeps yaw locked after mouse input")
	rig.free()
	return true


func _board_points(bounds: Rect2, extra_height: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var min_x := bounds.position.x
	var max_x := bounds.end.x
	var min_z := bounds.position.y
	var max_z := bounds.end.y
	for y: float in [0.0, 1.2 + extra_height]:
		points.append(Vector3(min_x, y, min_z))
		points.append(Vector3(max_x, y, min_z))
		points.append(Vector3(min_x, y, max_z))
		points.append(Vector3(max_x, y, max_z))
	return points


func _rig(viewport_size: Vector2 = Vector2(1080.0, 2400.0)) -> CameraRig:
	var tree := Engine.get_main_loop() as SceneTree
	var rig := CameraRig.new()
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 55.0
	rig.add_child(camera)
	rig.camera = camera
	tree.root.add_child(rig)
	rig.set_mobile_viewport_size(viewport_size)
	rig.set_mobile_board_bounds(Rect2(Vector2(-8.0, -8.0), Vector2(16.0, 16.0)))
	return rig
