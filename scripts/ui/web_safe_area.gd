class_name WebSafeArea
extends RefCounted

static var _test_insets: SafeInsets = null


static func set_test_insets(insets: SafeInsets) -> void:
	_test_insets = insets


static func clear_test_insets() -> void:
	_test_insets = null


static func get_insets() -> SafeInsets:
	if _test_insets != null:
		return _test_insets
	if not PlatformMode.is_web_runtime():
		return SafeInsets.zero()
	if not Engine.has_singleton("JavaScriptBridge"):
		return SafeInsets.zero()
	var result = JavaScriptBridge.eval(
		"window.chessfrontGetSafeInsets ? JSON.stringify(window.chessfrontGetSafeInsets()) : ''",
		true
	)
	return scale_insets(parse_insets(result), WebViewport.device_pixel_ratio())


static func scale_insets(insets: SafeInsets, pixel_ratio: float) -> SafeInsets:
	var scale := maxf(0.0, pixel_ratio)
	return SafeInsets.new(
		insets.left * scale,
		insets.top * scale,
		insets.right * scale,
		insets.bottom * scale
	)


static func parse_insets(value: Variant) -> SafeInsets:
	var data: Variant = value
	if value is String:
		var text := (value as String).strip_edges()
		if text.is_empty():
			return SafeInsets.zero()
		data = JSON.parse_string(text)
	if data is Dictionary:
		var dictionary := data as Dictionary
		return SafeInsets.new(
			float(dictionary.get("left", 0.0)),
			float(dictionary.get("top", 0.0)),
			float(dictionary.get("right", 0.0)),
			float(dictionary.get("bottom", 0.0))
		)
	return SafeInsets.zero()
