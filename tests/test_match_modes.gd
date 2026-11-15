extends TestCase


func test_shipped_mode_is_data_driven_and_enabled() -> bool:
	var built_in := MatchModeRegistry.built_in_modes()
	assert_eq(built_in.size(), 1, "one statically referenced shipped mode")
	assert_eq(built_in[0].id, "vs_ai", "built-in mode is Play vs AI")
	assert_true(
		built_in[0].resource_path.ends_with("resources/match_modes/vs_ai.tres"),
		"built-in mode keeps its resource path"
	)
	var paths := MatchModeRegistry.list_paths()
	assert_eq(paths.size(), 1, "one shipped mode resource")
	var modes := MatchModeRegistry.get_enabled_modes()
	assert_eq(modes.size(), 1, "one enabled mode")
	if modes.is_empty():
		return true
	var mode := modes[0]
	assert_eq(mode.id, "vs_ai", "mode id")
	assert_eq(mode.display_name, "Play vs AI", "mode display name")
	assert_true(mode.enabled, "mode is enabled")
	assert_true(mode.uses_ai(), "mode uses the AI opponent")
	assert_false(mode.description.is_empty(), "mode has a description")
	assert_eq(MatchModeRegistry.get_mode("vs_ai").id, "vs_ai", "get_mode finds the mode")
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
