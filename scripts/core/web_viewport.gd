class_name WebViewport
extends RefCounted

static var _test_pixel_ratio: float = -1.0
static var _test_landscape: int = -1


static func set_test_pixel_ratio(value: float) -> void:
	_test_pixel_ratio = value if value > 0.0 else -1.0


static func clear_test_pixel_ratio() -> void:
	_test_pixel_ratio = -1.0


static func set_test_landscape(value: bool) -> void:
	_test_landscape = 1 if value else 0


static func clear_test_landscape() -> void:
	_test_landscape = -1


static func is_landscape() -> bool:
	if _test_landscape != -1:
		return _test_landscape == 1
	if not PlatformMode.is_web_runtime():
		return false
	if not Engine.has_singleton("JavaScriptBridge"):
		return false
	var result = JavaScriptBridge.eval(
		"window.innerWidth > window.innerHeight ? 1 : 0", true
	)
	if result is bool:
		return bool(result)
	if result is int or result is float:
		return int(result) == 1
	return false


static func resolve_orientation_pause(
	is_web: bool,
	mobile_ui: bool,
	landscape: bool
) -> bool:
	return is_web and mobile_ui and landscape


static func notify_ready() -> void:
	if not PlatformMode.is_web_runtime():
		return
	if not Engine.has_singleton("JavaScriptBridge"):
		return
	JavaScriptBridge.eval(
		"window.chessfrontMarkReady ? window.chessfrontMarkReady() : null", true
	)


static func device_pixel_ratio() -> float:
	if _test_pixel_ratio > 0.0:
		return _test_pixel_ratio
	if not PlatformMode.is_web_runtime():
		return 1.0
	if not Engine.has_singleton("JavaScriptBridge"):
		return 1.0
	var result = JavaScriptBridge.eval("window.devicePixelRatio || 1", true)
	if result is int or result is float:
		return maxf(1.0, float(result))
	return 1.0
