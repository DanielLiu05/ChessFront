extends TestCase


func test_adapter_forwards_tap() -> bool:
	var adapter := _adapter()
	var counts := {"tap": 0}
	adapter.tap_requested.connect(
		func(_position: Vector2) -> void: counts["tap"] += 1
	)
	adapter._unhandled_input(_touch(0, Vector2(100.0, 100.0), true))
	adapter._unhandled_input(_touch(0, Vector2(100.0, 100.0), false))
	assert_eq(counts["tap"], 1, "adapter forwards a tap")
	adapter.free()
	return true


func test_adapter_forwards_pan_and_pinch() -> bool:
	var adapter := _adapter()
	var counts := {"pan": 0, "pinch": 0}
	adapter.pan_requested.connect(
		func(_delta: Vector2) -> void: counts["pan"] += 1
	)
	adapter.pinch_requested.connect(
		func(_factor: float) -> void: counts["pinch"] += 1
	)
	adapter._unhandled_input(_touch(0, Vector2(10.0, 10.0), true))
	adapter._unhandled_input(_drag(0, Vector2(40.0, 10.0)))
	assert_true(counts["pan"] > 0, "adapter forwards a pan")
	adapter._unhandled_input(_touch(0, Vector2(10.0, 10.0), false))
	adapter._unhandled_input(_touch(0, Vector2.ZERO, true))
	adapter._unhandled_input(_touch(1, Vector2(100.0, 0.0), true))
	adapter._unhandled_input(_drag(1, Vector2(130.0, 0.0)))
	assert_true(counts["pinch"] > 0, "adapter forwards a pinch")
	adapter._unhandled_input(_touch(1, Vector2(130.0, 0.0), false))
	adapter._unhandled_input(_touch(0, Vector2.ZERO, false))
	adapter.free()
	return true


func test_adapter_forwards_double_tap_and_long_press() -> bool:
	var adapter := _adapter()
	var counts := {"double": 0, "long": 0}
	adapter.double_tap_requested.connect(
		func(_position: Vector2) -> void: counts["double"] += 1
	)
	adapter.long_press_requested.connect(
		func(_position: Vector2) -> void: counts["long"] += 1
	)
	adapter._unhandled_input(_touch(0, Vector2(50.0, 50.0), true))
	adapter._unhandled_input(_touch(0, Vector2(50.0, 50.0), false))
	adapter._unhandled_input(_touch(0, Vector2(50.0, 50.0), true))
	adapter._unhandled_input(_touch(0, Vector2(50.0, 50.0), false))
	assert_true(counts["double"] > 0, "adapter forwards a double-tap")
	adapter.gesture.feed_touch_down(0, Vector2(80.0, 80.0), 0)
	adapter.gesture.update(400)
	adapter.gesture.feed_touch_up(0, Vector2(80.0, 80.0), 450)
	assert_eq(counts["long"], 1, "adapter forwards a long press")
	adapter.free()
	return true


func test_pause_cancels_active_gesture() -> bool:
	var adapter := _adapter()
	var counts := {"tap": 0}
	adapter.tap_requested.connect(
		func(_position: Vector2) -> void: counts["tap"] += 1
	)
	adapter._unhandled_input(_touch(0, Vector2(100.0, 100.0), true))
	adapter._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	adapter._unhandled_input(_touch(0, Vector2(100.0, 100.0), false))
	assert_eq(counts["tap"], 0, "pause cancels an active gesture")
	adapter.free()
	return true


func test_disabled_adapter_ignores_touch() -> bool:
	var adapter := _adapter()
	adapter.set_enabled(false)
	var counts := {"tap": 0}
	adapter.tap_requested.connect(
		func(_position: Vector2) -> void: counts["tap"] += 1
	)
	adapter._unhandled_input(_touch(0, Vector2(100.0, 100.0), true))
	adapter._unhandled_input(_touch(0, Vector2(100.0, 100.0), false))
	assert_eq(counts["tap"], 0, "disabled adapter ignores input")
	adapter.free()
	return true


func _adapter() -> TouchInputAdapter:
	var tree := Engine.get_main_loop() as SceneTree
	var adapter := TouchInputAdapter.new()
	tree.root.add_child(adapter)
	adapter.set_enabled(true)
	return adapter


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
