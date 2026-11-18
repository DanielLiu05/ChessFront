class_name SafeAreaContainer
extends MarginContainer

var _test_insets: SafeInsets = null
var _applied: SafeInsets = SafeInsets.zero()


func _ready() -> void:
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_apply_insets):
		viewport.size_changed.connect(_apply_insets)
	_apply_insets()


func _exit_tree() -> void:
	var viewport := get_viewport()
	if viewport != null and viewport.size_changed.is_connected(_apply_insets):
		viewport.size_changed.disconnect(_apply_insets)


func set_test_insets(insets: SafeInsets) -> void:
	_test_insets = insets
	_apply_insets()


func clear_test_insets() -> void:
	_test_insets = null
	_apply_insets()


func get_applied_insets() -> SafeInsets:
	return _applied


func apply_insets() -> void:
	_apply_insets()


func _apply_insets() -> void:
	var insets := _test_insets
	if insets == null:
		insets = _read_screen_insets()
	_applied = insets
	add_theme_constant_override("margin_left", roundi(insets.left))
	add_theme_constant_override("margin_top", roundi(insets.top))
	add_theme_constant_override("margin_right", roundi(insets.right))
	add_theme_constant_override("margin_bottom", roundi(insets.bottom))


func _read_screen_insets() -> SafeInsets:
	if PlatformMode.is_web_runtime():
		return WebSafeArea.get_insets()
	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return SafeInsets.zero()
	var viewport_size := Vector2(window_size)
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return SafeInsets.zero()
	return MobileMetrics.safe_insets(
		DisplayServer.get_display_safe_area(),
		DisplayServer.window_get_position(),
		window_size,
		viewport_size
	)
