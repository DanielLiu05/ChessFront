extends TestCase


func test_device_based_mobile_ui_resolution() -> bool:
	assert_false(
		PlatformMode.resolve_mobile_ui(false, false, false, false, false),
		"native desktop uses desktop UI"
	)
	assert_true(
		PlatformMode.resolve_mobile_ui(false, true, false, false, false),
		"native mobile uses mobile UI"
	)
	assert_false(
		PlatformMode.resolve_mobile_ui(true, false, false, false, false),
		"PC browser uses desktop UI"
	)
	assert_true(
		PlatformMode.resolve_mobile_ui(true, false, true, false, false),
		"Android browser uses mobile UI"
	)
	assert_true(
		PlatformMode.resolve_mobile_ui(true, false, false, true, false),
		"iOS browser uses mobile UI"
	)
	assert_true(
		PlatformMode.resolve_mobile_ui(true, false, false, false, true),
		"iPadOS touch uses mobile UI"
	)
	assert_false(
		PlatformMode.resolve_mobile_ui(true, false, false, false, false),
		"unknown web client stays desktop"
	)
	return true


func test_runtime_overrides() -> bool:
	PlatformMode.set_test_overrides(1, 0, 0)
	assert_true(PlatformMode.use_mobile_ui(), "mobile override wins")
	assert_false(PlatformMode.is_web_runtime(), "web override is off")

	PlatformMode.set_test_overrides(0, 1, 1)
	assert_false(PlatformMode.use_mobile_ui(), "desktop override wins")
	assert_true(PlatformMode.is_web_runtime(), "web override is on")

	PlatformMode.set_test_overrides(-1, 1, 1)
	assert_true(PlatformMode.use_mobile_ui(), "iPadOS touch resolves to mobile")

	PlatformMode.set_test_overrides(-1, 1, 0)
	assert_false(PlatformMode.use_mobile_ui(), "web without mobile tags stays desktop")

	PlatformMode.clear_test_overrides()
	return true
