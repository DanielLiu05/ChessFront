extends TestCase


func test_tap_dispatches_immediately() -> bool:
	var recognizer := _recognizer()
	var counts := {"tap": 0, "handled": 0, "double": 0}
	recognizer.tap_handler = func(_position: Vector2) -> bool: return true
	recognizer.tap_dispatched.connect(
		func(_position: Vector2, handled: bool) -> void:
			counts["tap"] += 1
			if handled:
				counts["handled"] += 1
	)
	recognizer.double_tapped.connect(
		func(_position: Vector2) -> void: counts["double"] += 1
	)
	recognizer.feed_touch_down(0, Vector2(100.0, 100.0), 1000)
	recognizer.feed_touch_up(0, Vector2(102.0, 101.0), 1050)
	assert_eq(counts["tap"], 1, "tap dispatches on release")
	assert_eq(counts["handled"], 1, "tap handler result is reported")
	assert_eq(counts["double"], 0, "a handled tap does not seed a double-tap")
	return true


func test_drag_becomes_pan_not_tap() -> bool:
	var recognizer := _recognizer()
	var counts := {"tap": 0, "pan": 0, "long": 0}
	recognizer.tap_handler = func(_position: Vector2) -> bool: return true
	recognizer.tap_dispatched.connect(
		func(_position: Vector2, _handled: bool) -> void: counts["tap"] += 1
	)
	recognizer.panned.connect(
		func(_delta: Vector2) -> void: counts["pan"] += 1
	)
	recognizer.long_pressed.connect(
		func(_position: Vector2) -> void: counts["long"] += 1
	)
	recognizer.feed_touch_down(0, Vector2.ZERO, 1000)
	recognizer.feed_touch_drag(0, Vector2(20.0, 0.0), 1100)
	recognizer.update(1600)
	recognizer.feed_touch_up(0, Vector2(20.0, 0.0), 1700)
	assert_true(counts["pan"] > 0, "drag emits pan")
	assert_eq(counts["tap"], 0, "drag never emits tap")
	assert_eq(counts["long"], 0, "drag cancels long press")
	return true


func test_long_press_suppresses_tap() -> bool:
	var recognizer := _recognizer()
	var counts := {"tap": 0, "long": 0}
	recognizer.tap_handler = func(_position: Vector2) -> bool: return true
	recognizer.tap_dispatched.connect(
		func(_position: Vector2, _handled: bool) -> void: counts["tap"] += 1
	)
	recognizer.long_pressed.connect(
		func(_position: Vector2) -> void: counts["long"] += 1
	)
	recognizer.feed_touch_down(0, Vector2(50.0, 50.0), 1000)
	recognizer.update(1399)
	assert_eq(counts["long"], 0, "long press waits for 400ms")
	recognizer.update(1400)
	recognizer.feed_touch_up(0, Vector2(50.0, 50.0), 1450)
	assert_eq(counts["long"], 1, "long press fires at 400ms")
	assert_eq(counts["tap"], 0, "long press suppresses the release tap")
	return true


func test_double_tap_only_after_unhandled_tap() -> bool:
	var unhandled := _recognizer()
	var unhandled_counts := {"tap": 0, "double": 0}
	unhandled.tap_handler = func(_position: Vector2) -> bool: return false
	unhandled.tap_dispatched.connect(
		func(_position: Vector2, _handled: bool) -> void: unhandled_counts["tap"] += 1
	)
	unhandled.double_tapped.connect(
		func(_position: Vector2) -> void: unhandled_counts["double"] += 1
	)
	unhandled.feed_touch_down(0, Vector2(10.0, 10.0), 1000)
	unhandled.feed_touch_up(0, Vector2(10.0, 10.0), 1030)
	unhandled.feed_touch_down(0, Vector2(11.0, 10.0), 1150)
	unhandled.feed_touch_up(0, Vector2(11.0, 10.0), 1180)
	assert_eq(unhandled_counts["tap"], 2, "both taps are dispatched immediately")
	assert_eq(unhandled_counts["double"], 1, "two unhandled taps zoom")
	var handled := _recognizer()
	var handled_counts := {"tap": 0, "double": 0}
	handled.tap_handler = func(_position: Vector2) -> bool: return true
	handled.tap_dispatched.connect(
		func(_position: Vector2, _is_handled: bool) -> void: handled_counts["tap"] += 1
	)
	handled.double_tapped.connect(
		func(_position: Vector2) -> void: handled_counts["double"] += 1
	)
	handled.feed_touch_down(0, Vector2(30.0, 30.0), 2000)
	handled.feed_touch_up(0, Vector2(30.0, 30.0), 2030)
	handled.feed_touch_down(0, Vector2(30.0, 30.0), 2150)
	handled.feed_touch_up(0, Vector2(30.0, 30.0), 2180)
	assert_eq(handled_counts["tap"], 2, "handled taps still dispatch")
	assert_eq(handled_counts["double"], 0, "handled taps never trigger zoom")
	return true


func test_double_tap_window_and_slop() -> bool:
	var late := _recognizer()
	var late_counts := {"double": 0}
	late.tap_handler = func(_position: Vector2) -> bool: return false
	late.double_tapped.connect(
		func(_position: Vector2) -> void: late_counts["double"] += 1
	)
	late.feed_touch_down(0, Vector2.ZERO, 1000)
	late.feed_touch_up(0, Vector2.ZERO, 1030)
	late.feed_touch_down(0, Vector2.ZERO, 1400)
	late.feed_touch_up(0, Vector2.ZERO, 1430)
	assert_eq(late_counts["double"], 0, "late second tap is not a double-tap")
	var far := _recognizer()
	var far_counts := {"double": 0}
	far.tap_handler = func(_position: Vector2) -> bool: return false
	far.double_tapped.connect(
		func(_position: Vector2) -> void: far_counts["double"] += 1
	)
	far.feed_touch_down(0, Vector2.ZERO, 2000)
	far.feed_touch_up(0, Vector2.ZERO, 2030)
	far.feed_touch_down(0, Vector2(100.0, 0.0), 2100)
	far.feed_touch_up(0, Vector2(100.0, 0.0), 2130)
	assert_eq(far_counts["double"], 0, "second tap outside slop is not a double-tap")
	return true


func test_second_touch_cancels_tap_and_starts_pinch() -> bool:
	var recognizer := _recognizer()
	var counts := {"tap": 0, "long": 0, "pinch": 0, "pan": 0}
	recognizer.tap_handler = func(_position: Vector2) -> bool: return true
	recognizer.tap_dispatched.connect(
		func(_position: Vector2, _handled: bool) -> void: counts["tap"] += 1
	)
	recognizer.long_pressed.connect(
		func(_position: Vector2) -> void: counts["long"] += 1
	)
	recognizer.pinched.connect(
		func(_factor: float) -> void: counts["pinch"] += 1
	)
	recognizer.panned.connect(
		func(_delta: Vector2) -> void: counts["pan"] += 1
	)
	recognizer.feed_touch_down(0, Vector2.ZERO, 1000)
	recognizer.feed_touch_down(1, Vector2(100.0, 0.0), 1010)
	recognizer.feed_touch_drag(1, Vector2(120.0, 0.0), 1020)
	recognizer.update(2000)
	recognizer.feed_touch_up(1, Vector2(120.0, 0.0), 2050)
	recognizer.feed_touch_up(0, Vector2.ZERO, 2100)
	assert_true(counts["pinch"] > 0, "two-touch distance change emits pinch")
	assert_eq(counts["tap"], 0, "pinch suppresses tap")
	assert_eq(counts["long"], 0, "pinch suppresses long press")
	assert_eq(counts["pan"], 0, "pinch does not emit pan")
	return true


func test_twist_only_pinches_does_not_pan() -> bool:
	var recognizer := _recognizer()
	var counts := {"pinch": 0, "pan": 0}
	recognizer.pinched.connect(
		func(_factor: float) -> void: counts["pinch"] += 1
	)
	recognizer.panned.connect(
		func(_delta: Vector2) -> void: counts["pan"] += 1
	)
	recognizer.feed_touch_down(0, Vector2.ZERO, 1000)
	recognizer.feed_touch_down(1, Vector2(100.0, 0.0), 1010)
	recognizer.feed_touch_drag(0, Vector2(0.0, 20.0), 1020)
	recognizer.feed_touch_drag(1, Vector2(100.0, 0.0), 1030)
	assert_true(counts["pinch"] > 0, "twist changes the pinch distance")
	assert_eq(counts["pan"], 0, "twist never emits pan")
	return true


func test_third_touch_cancels_gesture() -> bool:
	var recognizer := _recognizer()
	var counts := {"cancel": 0, "pinch": 0, "tap": 0}
	recognizer.cancelled.connect(func() -> void: counts["cancel"] += 1)
	recognizer.pinched.connect(
		func(_factor: float) -> void: counts["pinch"] += 1
	)
	recognizer.tap_dispatched.connect(
		func(_position: Vector2, _handled: bool) -> void: counts["tap"] += 1
	)
	recognizer.feed_touch_down(0, Vector2.ZERO, 1000)
	recognizer.feed_touch_down(1, Vector2(100.0, 0.0), 1010)
	recognizer.feed_touch_down(2, Vector2(200.0, 0.0), 1020)
	recognizer.feed_touch_drag(2, Vector2(220.0, 0.0), 1030)
	recognizer.feed_touch_up(2, Vector2(220.0, 0.0), 1040)
	recognizer.feed_touch_up(1, Vector2(100.0, 0.0), 1050)
	recognizer.feed_touch_up(0, Vector2.ZERO, 1060)
	assert_eq(counts["cancel"], 1, "third touch cancels the gesture")
	assert_eq(counts["pinch"], 0, "cancelled gesture emits no pinch")
	assert_eq(counts["tap"], 0, "cancelled gesture emits no tap")
	assert_eq(recognizer.active_touch_count(), 0, "cancelled touches are cleared")
	return true


func test_cancel_clears_active_gesture() -> bool:
	var recognizer := _recognizer()
	var counts := {"cancel": 0, "long": 0, "tap": 0}
	recognizer.tap_handler = func(_position: Vector2) -> bool: return true
	recognizer.cancelled.connect(func() -> void: counts["cancel"] += 1)
	recognizer.long_pressed.connect(
		func(_position: Vector2) -> void: counts["long"] += 1
	)
	recognizer.tap_dispatched.connect(
		func(_position: Vector2, _handled: bool) -> void: counts["tap"] += 1
	)
	recognizer.feed_touch_down(0, Vector2.ZERO, 1000)
	recognizer.cancel()
	recognizer.update(2000)
	recognizer.feed_touch_up(0, Vector2.ZERO, 2050)
	assert_eq(counts["cancel"], 1, "cancel emits once")
	assert_eq(counts["long"], 0, "cancel prevents long press")
	assert_eq(counts["tap"], 0, "cancel prevents tap")
	return true


func test_tap_slop_scales_with_dpi() -> bool:
	var within := _recognizer(320.0)
	var within_counts := {"tap": 0, "pan": 0}
	within.tap_handler = func(_position: Vector2) -> bool: return true
	within.tap_dispatched.connect(
		func(_position: Vector2, _handled: bool) -> void: within_counts["tap"] += 1
	)
	within.panned.connect(
		func(_delta: Vector2) -> void: within_counts["pan"] += 1
	)
	within.feed_touch_down(0, Vector2.ZERO, 1000)
	within.feed_touch_drag(0, Vector2(15.0, 0.0), 1050)
	within.feed_touch_up(0, Vector2(15.0, 0.0), 1100)
	assert_eq(within.tap_slop(), 20.0, "10dp at 320 dpi is 20 UI units")
	assert_eq(within_counts["tap"], 1, "movement inside slop remains a tap")
	assert_eq(within_counts["pan"], 0, "movement inside slop is not a pan")
	var beyond := _recognizer(320.0)
	var beyond_counts := {"tap": 0, "pan": 0}
	beyond.tap_handler = func(_position: Vector2) -> bool: return true
	beyond.tap_dispatched.connect(
		func(_position: Vector2, _handled: bool) -> void: beyond_counts["tap"] += 1
	)
	beyond.panned.connect(
		func(_delta: Vector2) -> void: beyond_counts["pan"] += 1
	)
	beyond.feed_touch_down(0, Vector2.ZERO, 1000)
	beyond.feed_touch_drag(0, Vector2(25.0, 0.0), 1050)
	beyond.feed_touch_up(0, Vector2(25.0, 0.0), 1100)
	assert_true(beyond_counts["pan"] > 0, "movement beyond slop pans")
	assert_eq(beyond_counts["tap"], 0, "movement beyond slop does not tap")
	return true


func _recognizer(dpi: float = 160.0) -> GestureRecognizer:
	var recognizer := GestureRecognizer.new()
	recognizer.configure(dpi, 1.0)
	return recognizer
