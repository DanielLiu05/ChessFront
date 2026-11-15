extends TestCase


func test_dp_conversion_and_touch_target() -> bool:
	assert_eq(MobileMetrics.dp_to_px(44.0, 160.0), 44.0, "160 dpi is one px per dp")
	assert_eq(MobileMetrics.dp_to_px(44.0, 320.0), 88.0, "dp scales with dpi")
	assert_eq(MobileMetrics.touch_target_px(420.0), 115.5, "44dp at 420 dpi")
	assert_eq(
		MobileMetrics.dp_to_ui(44.0, 320.0, 2.0),
		44.0,
		"content scale converts physical pixels to UI units"
	)
	assert_true(MobileMetrics.screen_dpi() > 0.0, "screen dpi has a positive fallback")
	MobileMetrics.set_dpi_override(420.0)
	assert_eq(MobileMetrics.screen_dpi(), 420.0, "test dpi override")
	assert_eq(MobileMetrics.touch_target_px(), 115.5, "touch target uses the override")
	MobileMetrics.clear_dpi_override()
	assert_true(MobileMetrics.screen_dpi() > 0.0, "clearing the override restores screen dpi")
	return true


func test_safe_insets_conversion() -> bool:
	var portrait := SafeInsets.from_rect(
		Rect2i(0, 80, 1080, 2240),
		Rect2i(0, 0, 1080, 2400)
	)
	assert_eq(portrait.top, 80.0, "top safe inset")
	assert_eq(portrait.bottom, 80.0, "bottom safe inset")
	assert_eq(portrait.left, 0.0, "left safe inset")
	assert_eq(portrait.right, 0.0, "right safe inset")
	assert_true(not portrait.is_zero(), "non-zero safe area")
	var scaled := SafeInsets.from_rect(
		Rect2i(10, 20, 1000, 600),
		Rect2i(0, 0, 1020, 640),
		Vector2(2.0, 2.0)
	)
	assert_eq(scaled.left, 20.0, "left inset scales to viewport units")
	assert_eq(scaled.top, 40.0, "top inset scales to viewport units")
	assert_eq(scaled.right, 20.0, "right inset scales to viewport units")
	assert_eq(scaled.bottom, 40.0, "bottom inset scales to viewport units")
	var outside := SafeInsets.from_rect(
		Rect2i(2000, 2000, 100, 100),
		Rect2i(0, 0, 1080, 2400)
	)
	assert_true(outside.is_zero(), "safe rect outside the window becomes zero")
	var empty_window := SafeInsets.from_rect(
		Rect2i(0, 0, 100, 100),
		Rect2i(0, 0, 0, 0)
	)
	assert_true(empty_window.is_zero(), "zero window produces zero insets")
	return true


func test_safe_area_container_applies_test_insets() -> bool:
	var container := SafeAreaContainer.new()
	container.set_test_insets(SafeInsets.new(10.0, 20.0, 30.0, 40.0))
	assert_eq(container.get_applied_insets().left, 10.0, "applied left inset")
	assert_eq(container.get_applied_insets().top, 20.0, "applied top inset")
	assert_eq(container.get_applied_insets().right, 30.0, "applied right inset")
	assert_eq(container.get_applied_insets().bottom, 40.0, "applied bottom inset")
	assert_eq(container.get_theme_constant("margin_left"), 10, "left margin override")
	assert_eq(container.get_theme_constant("margin_top"), 20, "top margin override")
	assert_eq(container.get_theme_constant("margin_right"), 30, "right margin override")
	assert_eq(container.get_theme_constant("margin_bottom"), 40, "bottom margin override")
	container.clear_test_insets()
	assert_not_null(container.get_applied_insets(), "clearing test insets keeps a value")
	container.free()
	return true


func test_mobile_project_settings() -> bool:
	assert_eq(
		int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)),
		1,
		"handheld orientation is portrait"
	)
	assert_false(
		bool(ProjectSettings.get_setting("application/config/quit_on_go_back", true)),
		"Android back does not quit the app"
	)
	assert_eq(
		String(ProjectSettings.get_setting("display/window/stretch/mode", "disabled")),
		"disabled",
		"desktop stretch settings remain unchanged"
	)
	assert_eq(
		String(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "")),
		"mobile",
		"mobile builds use the mobile renderer"
	)
	assert_eq(
		String(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")),
		"forward_plus",
		"desktop keeps the Forward+ renderer"
	)
	return true


func test_android_export_preset() -> bool:
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	assert_eq(error, OK, "export presets parse")
	if error != OK:
		return true
	var android_section := ""
	var game_section := ""
	for section: String in config.get_sections():
		if not section.begins_with("preset.") or section.ends_with(".options"):
			continue
		var platform := String(config.get_value(section, "platform", ""))
		if platform == "Android":
			android_section = section
		elif String(config.get_value(section, "name", "")) == "Game":
			game_section = section
	assert_ne(android_section, "", "Android preset exists")
	assert_ne(game_section, "", "desktop game preset exists")
	if android_section.is_empty() or game_section.is_empty():
		return true
	assert_eq(
		String(config.get_value(android_section, "name", "")),
		"Android",
		"Android preset name"
	)
	assert_true(
		String(config.get_value(android_section, "export_path", "")).begins_with(
			"builds/android/"
		),
		"Android APK path"
	)
	assert_true(
		String(config.get_value(android_section, "exclude_filter", "")).contains("editor/"),
		"Android export excludes the editor"
	)
	assert_true(
		String(config.get_value(android_section, "exclude_filter", "")).contains("tests/"),
		"Android export excludes tests"
	)
	var android_options := android_section + ".options"
	var option_keys := config.get_section_keys(android_options)
	assert_true(not option_keys.is_empty(), "Android preset has options")
	assert_true(option_keys.has("package/unique_name"), "Android package id is set")
	assert_true(option_keys.has("architectures/arm64-v8a"), "arm64 architecture is set")
	assert_true(option_keys.has("screen/edge_to_edge"), "edge-to-edge is configured")
	assert_eq(
		String(config.get_value(android_options, "package/unique_name", "")),
		"com.daniel.chessfront",
		"Android package id"
	)
	assert_true(
		bool(config.get_value(android_options, "architectures/arm64-v8a", false)),
		"arm64 is enabled"
	)
	var game_options := game_section + ".options"
	assert_true(not config.get_section_keys(game_options).is_empty(), "Game preset still has options")
	assert_true(
		String(config.get_value(game_section, "exclude_filter", "")).contains("editor/"),
		"Game preset still excludes the editor"
	)
	return true
