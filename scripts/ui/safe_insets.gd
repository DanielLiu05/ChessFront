class_name SafeInsets
extends RefCounted

var left: float = 0.0
var top: float = 0.0
var right: float = 0.0
var bottom: float = 0.0


func _init(
	p_left: float = 0.0,
	p_top: float = 0.0,
	p_right: float = 0.0,
	p_bottom: float = 0.0
) -> void:
	left = maxf(0.0, p_left)
	top = maxf(0.0, p_top)
	right = maxf(0.0, p_right)
	bottom = maxf(0.0, p_bottom)


static func zero() -> SafeInsets:
	return SafeInsets.new()


static func from_rect(
	safe_rect: Rect2i,
	window_rect: Rect2i,
	viewport_scale: Vector2 = Vector2.ONE
) -> SafeInsets:
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return zero()
	if window_rect.size.x <= 0 or window_rect.size.y <= 0:
		return zero()
	var inner := safe_rect.intersection(window_rect)
	if inner.size.x <= 0 or inner.size.y <= 0:
		return zero()
	var scale := Vector2(
		maxf(0.0, viewport_scale.x),
		maxf(0.0, viewport_scale.y)
	)
	return SafeInsets.new(
		(inner.position.x - window_rect.position.x) * scale.x,
		(inner.position.y - window_rect.position.y) * scale.y,
		(window_rect.end.x - inner.end.x) * scale.x,
		(window_rect.end.y - inner.end.y) * scale.y
	)


func is_zero() -> bool:
	return is_equal_approx(left, 0.0) \
		and is_equal_approx(top, 0.0) \
		and is_equal_approx(right, 0.0) \
		and is_equal_approx(bottom, 0.0)


func to_vector4() -> Vector4:
	return Vector4(left, top, right, bottom)


func equals(other: SafeInsets) -> bool:
	if other == null:
		return false
	return is_equal_approx(left, other.left) \
		and is_equal_approx(top, other.top) \
		and is_equal_approx(right, other.right) \
		and is_equal_approx(bottom, other.bottom)
