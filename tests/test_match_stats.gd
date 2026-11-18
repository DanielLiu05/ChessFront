extends TestCase


func test_stats_count_only_local_results() -> bool:
	var stats := MatchStats.new()
	var result := ActionResult.new()
	result.captured_unit = GameUnit.new(1, UnitType.Type.PAWN, GameConfig.Player.PLAYER_2, Vector2i(3, 3))
	stats.note_result(result, -1, GameConfig.Player.PLAYER_1)
	assert_eq(stats.captures, 1, "enemy capture counts")

	var own_loss := ActionResult.new()
	own_loss.captured_unit = GameUnit.new(2, UnitType.Type.PAWN, GameConfig.Player.PLAYER_1, Vector2i(3, 4))
	stats.note_result(own_loss, -1, GameConfig.Player.PLAYER_1)
	assert_eq(stats.captures, 1, "losing a unit is not a local capture")

	var gold := ActionResult.new()
	gold.gold_gained[GameConfig.Player.PLAYER_1] = 3
	gold.gold_gained[GameConfig.Player.PLAYER_2] = 9
	stats.note_result(gold, -1, GameConfig.Player.PLAYER_1)
	assert_eq(stats.gold_earned, 3, "only local gold is earned")

	var ambush := ActionResult.new()
	ambush.ambushed = true
	stats.note_result(ambush, UnitType.Type.SCOUT, GameConfig.Player.PLAYER_1)
	assert_eq(stats.scouts_lost, 1, "scout ambush loss counts")
	stats.note_result(ambush, UnitType.Type.PAWN, GameConfig.Player.PLAYER_1)
	assert_eq(stats.scouts_lost, 1, "other losses do not count as scout losses")
	return true


func test_online_notes_and_reset() -> bool:
	var stats := MatchStats.new()
	stats.note_capture(GameConfig.Player.PLAYER_2, GameConfig.Player.PLAYER_1)
	stats.note_capture(GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_1)
	assert_eq(stats.captures, 1, "notes count enemy captures only")
	stats.note_gold(2)
	stats.note_gold(0)
	assert_eq(stats.gold_earned, 2, "notes add positive gold")
	stats.note_ambush_loss(UnitType.Type.SCOUT)
	assert_eq(stats.scouts_lost, 1, "online scout loss")
	stats.reset()
	assert_eq(stats.captures, 0, "reset captures")
	assert_eq(stats.gold_earned, 0, "reset gold")
	assert_eq(stats.scouts_lost, 0, "reset scouts")
	return true


func test_game_over_rows_read_the_model() -> bool:
	var state := MovementTestUtils.empty_state()
	assert_not_null(state, "test state loads")
	if state == null:
		return false
	var model := PresentationModel.new(state, GameConfig.Player.PLAYER_1)
	model.stats.captures = 2
	model.stats.gold_earned = 5
	model.stats.scouts_lost = 1
	var rows := HudFormat.game_over_stat_rows(model)
	assert_eq(rows.size(), 5, "five match stat rows")
	var by_label: Dictionary[String, String] = {}
	for row: Dictionary in rows:
		by_label[String(row["label"])] = String(row["value"])
	assert_eq(by_label["Plies"], "0 / %d" % state.turn_limit_plies, "plies row")
	assert_eq(by_label["Captures"], "2", "captures row")
	assert_eq(by_label["Gold earned"], "5", "gold row")
	assert_eq(by_label["Mines held"], "0", "mines row")
	assert_eq(by_label["Scouts lost"], "1", "scout losses row")
	return true
