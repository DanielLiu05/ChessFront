extends TestCase


func test_parse_json_insets() -> bool:
	var insets := WebSafeArea.parse_insets(
		'{"left":8,"top":40,"right":4,"bottom":34}'
	)
	assert_true(insets.equals(SafeInsets.new(8.0, 40.0, 4.0, 34.0)), "JSON insets parse")
	return true


func test_parse_dictionary_insets_clamps_negative_values() -> bool:
	var insets := WebSafeArea.parse_insets({
		"left": -10,
		"top": 20,
		"right": "6",
		"bottom": 0,
	})
	assert_true(insets.equals(SafeInsets.new(0.0, 20.0, 6.0, 0.0)), "dictionary insets clamp")
	return true


func test_missing_or_invalid_insets_are_zero() -> bool:
	assert_true(WebSafeArea.parse_insets("").is_zero(), "empty string is zero")
	assert_true(WebSafeArea.parse_insets("not json").is_zero(), "invalid JSON is zero")
	assert_true(WebSafeArea.parse_insets(null).is_zero(), "null is zero")
	assert_true(WebSafeArea.parse_insets({}).is_zero(), "empty dictionary is zero")
	return true


func test_test_insets_override_bridge() -> bool:
	var expected := SafeInsets.new(11.0, 22.0, 33.0, 44.0)
	WebSafeArea.set_test_insets(expected)
	assert_true(WebSafeArea.get_insets().equals(expected), "test insets are returned")
	WebSafeArea.clear_test_insets()
	return true


func test_safe_insets_scale_to_canvas_units() -> bool:
	var scaled := WebSafeArea.scale_insets(
		SafeInsets.new(8.0, 40.0, 4.0, 34.0), 2.0
	)
	assert_true(
		scaled.equals(SafeInsets.new(16.0, 80.0, 8.0, 68.0)),
		"CSS safe insets scale by devicePixelRatio"
	)
	return true
