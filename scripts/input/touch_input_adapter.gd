class_name TouchInputAdapter
extends Node

signal pan_requested(delta: Vector2)
signal pinch_requested(factor: float)
signal tap_requested(position: Vector2)
signal long_press_requested(position: Vector2)
signal double_tap_requested(position: Vector2)
signal gesture_cancelled

var enabled: bool = false
var tap_handler: Callable = Callable()
var gesture_start_filter: Callable = Callable()
var gesture: GestureRecognizer


func _ready() -> void:
	_ensure_gesture()
	set_process(enabled)


func set_enabled(value: bool) -> void:
	enabled = value
	if enabled:
		_ensure_gesture()
	elif gesture != null:
		gesture.cancel()
	set_process(enabled)


func set_tap_handler(handler: Callable) -> void:
	tap_handler = handler
	if enabled:
		_ensure_gesture()


func set_gesture_start_filter(filter: Callable) -> void:
	gesture_start_filter = filter


func cancel_gesture() -> void:
	if gesture != null:
		gesture.cancel()


func _ensure_gesture() -> void:
	if gesture != null:
		return
	gesture = GestureRecognizer.new()
	_configure_gesture()
	gesture.panned.connect(_on_panned)
	gesture.pinched.connect(_on_pinched)
	gesture.long_pressed.connect(_on_long_pressed)
	gesture.double_tapped.connect(_on_double_tapped)
	gesture.cancelled.connect(_on_gesture_cancelled)


func _process(_delta: float) -> void:
	if not enabled:
		return
	_ensure_gesture()
	if gesture != null:
		gesture.update(Time.get_ticks_msec())


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	_ensure_gesture()
	if gesture == null:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if gesture_start_filter.is_valid() \
					and not bool(gesture_start_filter.call(touch.position)):
				_mark_input_handled()
				return
			gesture.feed_touch_down(
				touch.index, touch.position, Time.get_ticks_msec()
			)
		else:
			gesture.feed_touch_up(
				touch.index, touch.position, Time.get_ticks_msec()
			)
		_mark_input_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		gesture.feed_touch_drag(drag.index, drag.position, Time.get_ticks_msec())
		_mark_input_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_gesture()


func _dispatch_tap(position: Vector2) -> bool:
	tap_requested.emit(position)
	if tap_handler.is_valid():
		return bool(tap_handler.call(position))
	return false


func _configure_gesture() -> void:
	if gesture == null:
		return
	var content_scale := 1.0
	if is_inside_tree():
		var viewport_size := get_viewport().get_visible_rect().size
		var window_size := DisplayServer.window_get_size()
		if viewport_size.x > 0.0 and window_size.x > 0:
			content_scale = float(window_size.x) / viewport_size.x
	gesture.configure(MobileMetrics.screen_dpi(), content_scale)
	gesture.tap_handler = Callable(self, "_dispatch_tap")


func _on_panned(delta: Vector2) -> void:
	pan_requested.emit(delta)


func _on_pinched(factor: float) -> void:
	pinch_requested.emit(factor)


func _on_long_pressed(position: Vector2) -> void:
	long_press_requested.emit(position)


func _on_double_tapped(position: Vector2) -> void:
	double_tap_requested.emit(position)


func _on_gesture_cancelled() -> void:
	gesture_cancelled.emit()


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
