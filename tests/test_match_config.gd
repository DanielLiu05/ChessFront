extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2


func test_valid_config_and_ai_side() -> bool:
	var config := MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_2)
	assert_eq(config.mode_id, "vs_ai", "mode id")
	assert_eq(config.map_id, "borderlands", "map id")
	assert_eq(config.human_player, PLAYER_1, "human side")
	assert_eq(config.first_player, PLAYER_2, "first side")
	assert_true(config.uses_ai(), "AI mode is detected")
	assert_eq(config.ai_player(), PLAYER_2, "AI takes the other side")
	assert_false(config.first_is_human(), "AI moves first")
	assert_true(config.first_is_ai(), "first side is the AI")
	assert_eq(config.validation_errors().size(), 0, "valid config has no errors")
	return true


func test_human_can_play_player_2() -> bool:
	var config := MatchConfig.new("vs_ai", "river_crossing", PLAYER_2, PLAYER_2)
	assert_eq(config.human_player, PLAYER_2, "human plays player 2")
	assert_eq(config.ai_player(), PLAYER_1, "AI plays player 1")
	assert_true(config.first_is_human(), "human moves first")
	assert_false(config.first_is_ai(), "AI does not move first")
	assert_eq(config.side_label(PLAYER_2), "You", "local label")
	assert_eq(config.side_label(PLAYER_1), "AI", "AI label")
	assert_eq(config.first_label(), "You", "first label")
	assert_eq(config.validation_errors().size(), 0, "player-2 config is valid")
	return true


func test_invalid_config_is_rejected() -> bool:
	var no_mode := MatchConfig.new("missing_mode", "borderlands", PLAYER_1, PLAYER_1)
	assert_true(
		_errors_contain(no_mode.validation_errors(), "not available"),
		"unknown mode is reported"
	)
	var no_map := MatchConfig.new("vs_ai", "missing_map", PLAYER_1, PLAYER_1)
	assert_true(
		_errors_contain(no_map.validation_errors(), "not available"),
		"unknown map is reported"
	)
	var bad_side := MatchConfig.new("vs_ai", "borderlands", 7, PLAYER_1)
	assert_true(
		_errors_contain(bad_side.validation_errors(), "Human player"),
		"invalid human side is reported"
	)
	var bad_first := MatchConfig.new("vs_ai", "borderlands", PLAYER_1, 0)
	assert_true(
		_errors_contain(bad_first.validation_errors(), "First player"),
		"invalid first side is reported"
	)
	return true


func test_duplicate_config_is_independent() -> bool:
	var config := MatchConfig.new("vs_ai", "borderlands", PLAYER_1, PLAYER_1)
	var copy := config.duplicate_config()
	assert_eq(copy.summary_text(), config.summary_text(), "copy starts identical")
	copy.map_id = "highland_woods"
	copy.human_player = PLAYER_2
	assert_eq(config.map_id, "borderlands", "original map is unchanged")
	assert_eq(config.human_player, PLAYER_1, "original side is unchanged")
	return true


func test_summary_names_mode_map_and_sides() -> bool:
	var config := MatchConfig.new("vs_ai", "borderlands", PLAYER_2, PLAYER_1)
	var summary := config.summary_text()
	assert_true(summary.contains("Play vs AI"), "summary names the mode")
	assert_true(summary.contains("Borderlands"), "summary names the map")
	assert_true(summary.contains("You: Player 2"), "summary names the human side")
	assert_true(summary.contains("First: AI"), "summary names the first mover")
	return true


func _errors_contain(errors: Array[String], needle: String) -> bool:
	for message: String in errors:
		if message.contains(needle):
			return true
	return false
