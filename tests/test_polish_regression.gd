extends TestCase

const MAP_PATH: String = "res://maps/standard_template.json"
const PLIES: int = 30
const EXPECTED_HASH: String = "15276dca48af6cdd65c6b1ac012015c2a4dd491604952cd35e4a3d0548ac5d26"

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2


func test_scripted_ai_match_keeps_state_hash() -> bool:
	var loaded := MapIO.load_from_file(MAP_PATH)
	assert_true(loaded.is_valid(), "regression map loads")
	if not loaded.is_valid():
		return true
	var state := GameState.new(loaded.map, PLIES)
	var brains: Dictionary[int, AiBrain] = {
		PLAYER_1: AiBrain.new(),
		PLAYER_2: AiBrain.new(),
	}
	for ply_index in PLIES:
		if state.game_over:
			break
		var player := int(state.active_player)
		var observation := AiObservation.for_player(state, player)
		var decision: AiDecision = brains[player].decide(observation)
		var result := ActionResolver.resolve(state, decision.action, observation.view.exploration)
		assert_true(result.success, "ply %d resolves: %s" % [ply_index, result.error])
		if not result.success:
			break
		brains[player].record_committed(decision)
	var actual := state.snapshot_text().sha256_text()
	assert_eq(actual, EXPECTED_HASH, "polish regression state hash")
	return true
