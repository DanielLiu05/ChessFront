class_name GestureRecognizer
extends RefCounted

signal panned(delta: Vector2)
signal pinched(factor: float)
signal long_pressed(position: Vector2)
signal double_tapped(position: Vector2)
signal tap_dispatched(position: Vector2, handled: bool)
signal cancelled

const TAP_SLOP_DP: float = 10.0
const LONG_PRESS_MSEC: int = 400
const DOUBLE_TAP_MSEC: int = 300

var tap_handler: Callable = Callable()

var _tap_slop: float = TAP_SLOP_DP
var _touches: Dictionary[int, Vector2] = {}
var _primary_index: int = -1
var _primary_start: Vector2 = Vector2.ZERO
var _primary_last: Vector2 = Vector2.ZERO
var _primary_start_msec: int = 0
var _primary_moved: bool = false
var _primary_long_press: bool = false
var _pinching: bool = false
var _last_pinch_distance: float = 0.0
var _gesture_cancelled: bool = false
var _pending_tap_position: Vector2 = Vector2.ZERO
var _pending_tap_msec: int = 0
var _has_pending_tap: bool = false


func configure(dpi: float = -1.0, content_scale: float = 1.0) -> void:
	_tap_slop = MobileMetrics.dp_to_ui(TAP_SLOP_DP, dpi, content_scale)


func tap_slop() -> float:
	return _tap_slop


func active_touch_count() -> int:
	return _touches.size()


func has_pending_tap() -> bool:
	return _has_pending_tap


func is_pinching() -> bool:
	return _pinching


func feed_touch_down(index: int, position: Vector2, now_msec: int) -> void:
	_touches[index] = position
	if _gesture_cancelled:
		return
	if _touches.size() == 1:
		_primary_index = index
		_primary_start = position
		_primary_last = position
		_primary_start_msec = now_msec
		_primary_moved = false
		_primary_long_press = false
		_pinching = false
		_last_pinch_distance = 0.0
	elif _touches.size() == 2:
		_primary_long_press = false
		_clear_pending_tap()
		_pinching = true
		_last_pinch_distance = _two_touch_distance()
	else:
		_cancel_events()
		_gesture_cancelled = true


func feed_touch_drag(index: int, position: Vector2, now_msec: int) -> void:
	if not _touches.has(index):
		return
	_touches[index] = position
	if _gesture_cancelled:
		return
	if _pinching:
		var distance := _two_touch_distance()
		if _last_pinch_distance > 0.0 and distance > 0.0:
			var factor := distance / _last_pinch_distance
			if not is_equal_approx(factor, 1.0):
				pinched.emit(factor)
		_last_pinch_distance = distance
		return
	if _touches.size() != 1 or index != _primary_index:
		return
	if _primary_long_press:
		return
	if not _primary_moved:
		if position.distance_to(_primary_start) <= _tap_slop:
			_primary_last = position
			return
		_primary_moved = true
		_clear_pending_tap()
		panned.emit(position - _primary_start)
		_primary_last = position
		return
	var delta := position - _primary_last
	if not delta.is_zero_approx():
		panned.emit(delta)
		_primary_last = position


func update(now_msec: int) -> void:
	if _gesture_cancelled or _pinching or _primary_long_press or _primary_moved:
		return
	if _primary_index == -1 or _touches.size() != 1:
		return
	if now_msec - _primary_start_msec < LONG_PRESS_MSEC:
		return
	_primary_long_press = true
	_clear_pending_tap()
	long_pressed.emit(_primary_last)


func feed_touch_up(index: int, position: Vector2, now_msec: int) -> void:
	if not _touches.has(index):
		return
	_touches.erase(index)
	if _gesture_cancelled:
		if _touches.is_empty():
			_reset_all()
		return
	if _pinching:
		_pinching = false
		_last_pinch_distance = 0.0
		if _touches.is_empty():
			_reset_all()
		else:
			_gesture_cancelled = true
		return
	if index != _primary_index:
		if _touches.is_empty():
			_reset_all()
		return
	if _primary_long_press or _primary_moved:
		_reset_all()
		return
	var handled := false
	if tap_handler.is_valid():
		handled = bool(tap_handler.call(position))
	tap_dispatched.emit(position, handled)
	if handled:
		_clear_pending_tap()
	elif _has_pending_tap \
			and now_msec - _pending_tap_msec <= DOUBLE_TAP_MSEC \
			and position.distance_to(_pending_tap_position) <= _tap_slop:
		_clear_pending_tap()
		double_tapped.emit(position)
	else:
		_pending_tap_position = position
		_pending_tap_msec = now_msec
		_has_pending_tap = true
	_reset_active_touch()
	_primary_index = -1


func cancel() -> void:
	var had_active := not _touches.is_empty()
	_reset_all()
	if had_active:
		cancelled.emit()


func _two_touch_distance() -> float:
	if _touches.size() < 2:
		return 0.0
	var indices: Array = _touches.keys()
	var first: Vector2 = _touches[int(indices[0])]
	var second: Vector2 = _touches[int(indices[1])]
	return first.distance_to(second)


func _cancel_events() -> void:
	_pinching = false
	_last_pinch_distance = 0.0
	_primary_long_press = false
	_primary_moved = true
	_clear_pending_tap()
	cancelled.emit()


func _reset_active_touch() -> void:
	_touches.clear()
	_primary_index = -1
	_primary_moved = false
	_primary_long_press = false
	_pinching = false
	_last_pinch_distance = 0.0
	_gesture_cancelled = false


func _reset_all() -> void:
	_reset_active_touch()
	_clear_pending_tap()


func _clear_pending_tap() -> void:
	_has_pending_tap = false
	_pending_tap_position = Vector2.ZERO
	_pending_tap_msec = 0
