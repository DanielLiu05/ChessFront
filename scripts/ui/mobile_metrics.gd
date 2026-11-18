class_name MobileMetrics
extends RefCounted

const REFERENCE_DPI: float = 160.0
const TOUCH_TARGET_DP: float = 44.0

static var _dpi_override: float = -1.0


static func set_dpi_override(value: float) -> void:
	_dpi_override = value if value > 0.0 else -1.0


static func clear_dpi_override() -> void:
	_dpi_override = -1.0


static func screen_dpi() -> float:
	if _dpi_override > 0.0:
		return _dpi_override
	if PlatformMode.is_web_runtime():
		return REFERENCE_DPI * WebViewport.device_pixel_ratio()
	var dpi := DisplayServer.screen_get_dpi()
	return dpi if dpi > 0.0 else REFERENCE_DPI


static func dp_to_px(dp: float, dpi: float = -1.0) -> float:
	var resolved_dpi := dpi
	if resolved_dpi <= 0.0:
		resolved_dpi = screen_dpi()
	return dp * resolved_dpi / REFERENCE_DPI


static func dp_to_ui(
	dp: float,
	dpi: float = -1.0,
	content_scale: float = 1.0
) -> float:
	var scale := content_scale if content_scale > 0.0 else 1.0
	return dp_to_px(dp, dpi) / scale


static func touch_target_px(dpi: float = -1.0) -> float:
	return dp_to_px(TOUCH_TARGET_DP, dpi)


static func touch_target_ui(
	dpi: float = -1.0,
	content_scale: float = 1.0
) -> float:
	return dp_to_ui(TOUCH_TARGET_DP, dpi, content_scale)


static func viewport_scale(
	window_size: Vector2i,
	viewport_size: Vector2
) -> Vector2:
	if window_size.x <= 0 or window_size.y <= 0:
		return Vector2.ONE
	return viewport_size / Vector2(window_size)


static func safe_insets(
	safe_rect: Rect2i,
	window_position: Vector2i,
	window_size: Vector2i,
	viewport_size: Vector2
) -> SafeInsets:
	var window_rect := Rect2i(window_position, window_size)
	return SafeInsets.from_rect(
		safe_rect, window_rect, viewport_scale(window_size, viewport_size)
	)
