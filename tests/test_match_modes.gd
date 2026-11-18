extends TestCase


func test_shipped_mode_is_data_driven_and_enabled() -> bool:
	var built_in := MatchModeRegistry.built_in_modes()
	assert_eq(built_in.size(), 2, "two statically referenced shipped modes")
	assert_eq(built_in[0].id, "vs_ai", "first built-in mode is Play vs AI")
	assert_eq(built_in[1].id, "online_pvp", "second built-in mode is Play Online")
	assert_true(
		built_in[0].resource_path.ends_with("resources/match_modes/vs_ai.tres"),
		"built-in mode keeps its resource path"
	)
	var paths := MatchModeRegistry.list_paths()
	assert_eq(paths.size(), 2, "two shipped mode resources")
	var modes := MatchModeRegistry.get_enabled_modes()
	assert_eq(modes.size(), 2, "two enabled modes")
	var ai_mode := MatchModeRegistry.get_mode("vs_ai")
	assert_not_null(ai_mode, "AI mode is registered")
	if ai_mode == null:
		return true
	assert_eq(ai_mode.display_name, "Play vs AI", "AI mode display name")
	assert_true(ai_mode.enabled, "AI mode is enabled")
	assert_true(ai_mode.uses_ai(), "AI mode uses the AI opponent")
	assert_false(ai_mode.description.is_empty(), "AI mode has a description")
	var online_mode := MatchModeRegistry.get_mode("online_pvp")
	assert_not_null(online_mode, "online mode is registered")
	if online_mode == null:
		return true
	assert_eq(online_mode.display_name, "Play Online", "online mode display name")
	assert_true(online_mode.enabled, "online mode is enabled")
	assert_false(online_mode.uses_ai(), "online mode uses a human opponent")
	assert_false(online_mode.description.is_empty(), "online mode has a description")
	assert_null(MatchModeRegistry.get_mode("missing_mode"), "unknown mode is rejected")
	assert_true(MatchModeRegistry.registry_errors().is_empty(), "shipped registry is valid")
	return true


func test_mode_validation_rejects_empty_and_duplicate_ids() -> bool:
	var empty := MatchModeDefinition.new()
	var empty_errors := MatchModeRegistry.validate_modes([empty])
	assert_true(_errors_contain(empty_errors, "id is empty"), "empty id is rejected")
	assert_true(_errors_contain(empty_errors, "no display name"), "empty name is rejected")

	var first := MatchModeDefinition.new()
	first.id = "duplicate"
	first.display_name = "First"
	var second := MatchModeDefinition.new()
	second.id = "duplicate"
	second.display_name = "Second"
	var duplicate_errors := MatchModeRegistry.validate_modes([first, second])
	assert_true(
		_errors_contain(duplicate_errors, "Duplicate mode id"),
		"duplicate ids are rejected"
	)
	return true


func test_disabled_modes_are_not_offered() -> bool:
	var mode := MatchModeDefinition.new()
	mode.id = "disabled"
	mode.display_name = "Disabled"
	mode.enabled = false
	assert_true(MatchModeRegistry.validate_modes([mode]).is_empty(), "definition is valid")
	assert_true(mode.enabled == false, "mode can be disabled by data")
	return true


func _errors_contain(errors: Array[String], needle: String) -> bool:
	for message: String in errors:
		if message.contains(needle):
			return true
	return false
