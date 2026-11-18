extends TestCase

const WEB_PRESET_SHELL: String = "res://web/shell.html"


func test_web_export_preset_is_configured() -> bool:
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	assert_eq(error, OK, "export presets parse")
	if error != OK:
		return true
	var web_section := ""
	for section: String in config.get_sections():
		if not section.begins_with("preset.") or section.ends_with(".options"):
			continue
		if String(config.get_value(section, "platform", "")) == "Web":
			web_section = section
			break
	assert_ne(web_section, "", "Web preset exists")
	if web_section.is_empty():
		return true
	assert_eq(String(config.get_value(web_section, "name", "")), "Web", "Web preset name")
	assert_true(
		String(config.get_value(web_section, "export_path", "")).begins_with(
			"builds/web/"
		),
		"Web output path"
	)
	var include_filter := String(config.get_value(web_section, "include_filter", ""))
	assert_true(include_filter.contains("maps/library/"), "Web build includes maps")
	assert_true(
		include_filter.contains("resources/match_modes/"),
		"Web build includes mode resources"
	)
	var exclude_filter := String(config.get_value(web_section, "exclude_filter", ""))
	assert_true(exclude_filter.contains("editor/"), "Web build excludes the editor")
	assert_true(exclude_filter.contains("tests/"), "Web build excludes tests")

	var options := web_section + ".options"
	assert_false(
		bool(config.get_value(options, "variant/thread_support", true)),
		"single-threaded Web build"
	)
	assert_eq(
		String(config.get_value(options, "html/custom_html_shell", "")),
		WEB_PRESET_SHELL,
		"custom web shell is wired"
	)
	assert_eq(
		int(config.get_value(options, "html/canvas_resize_policy", -1)),
		2,
		"adaptive canvas resize"
	)
	assert_false(
		bool(config.get_value(options, "progressive_web_app/enabled", true)),
		"PWA remains off"
	)
	return true


func test_custom_shell_has_required_contract() -> bool:
	var text := FileAccess.get_file_as_string(WEB_PRESET_SHELL)
	assert_false(text.is_empty(), "custom shell exists")
	if text.is_empty():
		return true
	for placeholder: String in [
		"$GODOT_PROJECT_NAME",
		"$GODOT_CONFIG",
		"$GODOT_THREADS_ENABLED",
		"$GODOT_SPLASH",
		"$GODOT_SPLASH_CLASSES",
		"$GODOT_SPLASH_COLOR",
		"$GODOT_URL",
		"$GODOT_HEAD_INCLUDE",
	]:
		assert_true(text.contains(placeholder), "shell keeps %s" % placeholder)
	assert_true(text.contains("viewport-fit=cover"), "shell covers the safe viewport")
	assert_true(text.contains("100dvh"), "shell uses dynamic viewport height")
	assert_true(text.contains("chessfrontGetSafeInsets"), "safe-area JS bridge exists")
	assert_true(text.contains("safe-area-inset-top"), "safe-area CSS is present")
	assert_true(text.contains("touch-action: none"), "page touch gestures are disabled")
	assert_true(text.contains("id=\"play-overlay\""), "tap-to-play overlay exists")
	assert_true(text.contains("id=\"rotate-overlay\""), "rotate overlay exists")
	assert_true(text.contains("chessfrontMarkReady"), "ready signal is exposed")
	assert_true(text.contains("requestFullscreen"), "fullscreen request is present")
	assert_true(text.contains("screen.orientation.lock"), "orientation lock is present")
	assert_true(text.contains("Rotate to portrait"), "rotate copy exists")
	assert_true(text.contains("Tap to play"), "play copy exists")
	assert_true(text.contains("window.devicePixelRatio"), "mobile DPR cap is present")
	assert_true(text.contains("return 2.0"), "mobile DPR is capped at 2x")
	return true
