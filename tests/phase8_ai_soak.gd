extends SceneTree

const MAX_PLIES: int = GameConfig.DEFAULT_TURN_LIMIT_PLIES

var _failures: int = 0


func _initialize() -> void:
	var map_ids := MapLibrary.get_ids()
	if map_ids.is_empty():
		_fail("No library maps are available for the AI soak")
		_finish(0)
		return
	var started := Time.get_ticks_msec()
	for map_id: String in map_ids:
		for first_player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
			var first := _run_match(map_id, first_player)
			var second := _run_match(map_id, first_player)
			if first.is_empty() or second.is_empty():
				continue
			_compare_runs(map_id, first_player, first, second)
			print(
				"Soak %s first=P%d: plies=%d winner=%d draw=%s fallbacks=%d ms=%d"
				% [
					map_id,
					first_player,
					int(first["plies"]),
					int(first["winner"]),
					String(first["draw_reason"]),
					int(first["fallbacks"]),
					int(first["elapsed_ms"]),
				]
			)
	_finish(Time.get_ticks_msec() - started)


func _run_match(map_id: String, first_player: int) -> Dictionary:
	var loaded := MapLibrary.load_by_id(map_id)
	if not loaded.is_valid():
		_fail("Could not load %s: %s" % [map_id, str(loaded.errors)])
		return {}
	var state := GameState.new(loaded.map, MAX_PLIES, first_player)
	var brains: Dictionary[int, AiBrain] = {
		GameConfig.Player.PLAYER_1: AiBrain.new(),
		GameConfig.Player.PLAYER_2: AiBrain.new(),
	}
	var sequence: Array[String] = []
	var fallbacks := 0
	var started := Time.get_ticks_msec()
	while sequence.size() < MAX_PLIES and not state.game_over:
		var active := int(state.active_player)
		var observation := AiObservation.for_player(state, active)
		var decision: AiDecision = brains[active].decide(observation)
		if decision == null or decision.action == null:
			_fail("%s first=P%d: AI returned no action at ply %d" % [map_id, first_player, sequence.size()])
			break
		var result := ActionResolver.resolve(
			state, decision.action, observation.view.exploration
		)
		var actual := decision
		if not result.success:
			fallbacks += 1
			var fallback := PassAction.new()
			var fallback_result := ActionResolver.resolve(
				state, fallback, observation.view.exploration
			)
			if not fallback_result.success:
				_fail(
					"%s first=P%d: AI action and fallback pass were rejected at ply %d"
					% [map_id, first_player, sequence.size()]
				)
				break
			actual = AiDecision.new(
				fallback,
				AiDecision.Kind.PASS,
				0.0,
				-1,
				AiDecision.NO_TILE,
				AiDecision.NO_TILE,
				"Fallback pass"
			)
		brains[active].record_committed(actual)
		sequence.append(actual.signature())
	if not state.game_over:
		_fail(
			"%s first=P%d: match did not terminate within %d plies"
			% [map_id, first_player, MAX_PLIES]
		)
	if fallbacks > 0:
		_fail(
			"%s first=P%d: %d AI actions needed the pass fallback"
			% [map_id, first_player, fallbacks]
		)
	return {
		"map_id": map_id,
		"first_player": first_player,
		"plies": sequence.size(),
		"winner": state.winner,
		"draw_reason": state.draw_reason,
		"sequence": sequence,
		"snapshot": state.snapshot_text(),
		"fallbacks": fallbacks,
		"elapsed_ms": Time.get_ticks_msec() - started,
	}


func _compare_runs(
	map_id: String,
	first_player: int,
	first: Dictionary,
	second: Dictionary
) -> void:
	if first["sequence"] != second["sequence"]:
		_fail("%s first=P%d: repeated action sequences differ" % [map_id, first_player])
	if first["snapshot"] != second["snapshot"]:
		_fail("%s first=P%d: repeated final states differ" % [map_id, first_player])
	if first["winner"] != second["winner"] or first["draw_reason"] != second["draw_reason"]:
		_fail("%s first=P%d: repeated outcomes differ" % [map_id, first_player])


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)


func _finish(elapsed_ms: int) -> void:
	print("Phase 8 AI soak complete: %d failure(s), %d ms" % [_failures, elapsed_ms])
	quit(1 if _failures > 0 else 0)
