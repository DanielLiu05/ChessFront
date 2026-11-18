class_name PlatformMode
extends RefCounted

static var _mobile_ui_override: int = -1
static var _web_override: int = -1
static var _ipados_touch_override: int = -1


static func resolve_mobile_ui(
	is_web: bool,
	native_mobile: bool,
	web_android: bool,
	web_ios: bool,
	ipados_touch: bool
) -> bool:
	if not is_web:
		return native_mobile
	if web_android or web_ios:
		return true
	return ipados_touch


static func use_mobile_ui() -> bool:
	if _mobile_ui_override != -1:
		return _mobile_ui_override == 1
	if not is_web_runtime():
		return OS.has_feature("mobile")
	return resolve_mobile_ui(
		true,
		OS.has_feature("mobile"),
		OS.has_feature("web_android"),
		OS.has_feature("web_ios"),
		_detect_ipados_touch()
	)


static func is_web_runtime() -> bool:
	if _web_override != -1:
		return _web_override == 1
	return OS.has_feature("web")


static func set_test_overrides(
	mobile_ui: int = -1,
	web: int = -1,
	ipados_touch: int = -1
) -> void:
	_mobile_ui_override = _normalize_override(mobile_ui)
	_web_override = _normalize_override(web)
	_ipados_touch_override = _normalize_override(ipados_touch)


static func clear_test_overrides() -> void:
	_mobile_ui_override = -1
	_web_override = -1
	_ipados_touch_override = -1


static func _detect_ipados_touch() -> bool:
	if _ipados_touch_override != -1:
		return _ipados_touch_override == 1
	if not Engine.has_singleton("JavaScriptBridge"):
		return false
	var result = JavaScriptBridge.eval(
		"(navigator.maxTouchPoints > 1 && /Macintosh/.test(navigator.userAgent)) ? 1 : 0",
		true
	)
	if result is bool:
		return bool(result)
	if result is int or result is float:
		return int(result) == 1
	return false


static func _normalize_override(value: int) -> int:
	if value == 1:
		return 1
	if value == 0:
		return 0
	return -1
