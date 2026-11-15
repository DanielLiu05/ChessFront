extends TestCase

const PLAYER_1: int = GameConfig.Player.PLAYER_1
const PLAYER_2: int = GameConfig.Player.PLAYER_2
const CENTER: Vector2i = Vector2i(8, 8)


func test_hidden_enemy_and_terrain_do_not_change_decision() -> bool:
	var first := _state_with_scout()
	var second := _state_with_scout()
	if first == null or second == null:
		return true
	MovementTestUtils.add_unit(first, UnitType.Type.KING, PLAYER_2, Vector2i(8, 1))
	MovementTestUtils.add_unit(second, UnitType.Type.KING, PLAYER_2, Vector2i(7, 1))
	second.board.get_tile(Vector2i(0, 8)).terrain = TerrainType.Type.WATER
	first.refresh_vision()
	second.refresh_vision()

	var first_observation := AiObservation.for_player(first, PLAYER_1)
	var second_observation := AiObservation.for_player(second, PLAYER_1)
	_assert_same_observation(first_observation, second_observation)
	var first_brain := AiBrain.new()
	var second_brain := AiBrain.new()
	var first_decision := first_brain.decide(first_observation)
	var second_decision := second_brain.decide(second_observation)
	assert_not_null(first_decision, "first decision exists")
	assert_not_null(second_decision, "second decision exists")
	if first_decision == null or second_decision == null:
		return true
	assert_eq(
		first_decision.signature(),
		second_decision.signature(),
		"hidden state changes do not change the AI action"
	)
	assert_eq(
		first_brain.last_known_enemy_king_tile,
		AiBrain.NO_TILE,
		"AI has no memory of the hidden King"
	)
	assert_eq(
		second_brain.last_known_enemy_king_tile,
		AiBrain.NO_TILE,
		"AI has no memory of the relocated hidden King"
	)
	return true


func test_hidden_king_relocation_alone_is_invisible() -> bool:
	var first := _state_with_scout()
	var second := _state_with_scout()
	if first == null or second == null:
		return true
	MovementTestUtils.add_unit(first, UnitType.Type.KING, PLAYER_2, Vector2i(8, 1))
	MovementTestUtils.add_unit(second, UnitType.Type.KING, PLAYER_2, Vector2i(11, 1))
	first.refresh_vision()
	second.refresh_vision()
	var first_observation := AiObservation.for_player(first, PLAYER_1)
	var second_observation := AiObservation.for_player(second, PLAYER_1)
	_assert_same_observation(first_observation, second_observation)
	assert_eq(
		AiBrain.new().decide(first_observation).signature(),
		AiBrain.new().decide(second_observation).signature(),
		"relocating only the hidden King keeps the decision identical"
	)
	return true


func _assert_same_observation(first: AiObservation, second: AiObservation) -> void:
	assert_eq(
		_known_unit_ids(first.view),
		_known_unit_ids(second.view),
		"known units match"
	)
	assert_eq(
		first.view.knowledge.explored_tiles(),
		second.view.knowledge.explored_tiles(),
		"exploration matches"
	)
	assert_eq(
		first.view.knowledge.visible_tiles(),
		second.view.knowledge.visible_tiles(),
		"visibility matches"
	)
	assert_eq(first.view.known_mines, second.view.known_mines, "known mines match")
	assert_eq(
		first.view.visible_gold_token_tiles,
		second.view.visible_gold_token_tiles,
		"visible tokens match"
	)
	assert_eq(
		first.view.deployment_tiles,
		second.view.deployment_tiles,
		"deployment knowledge matches"
	)
	assert_eq(_terrain_signature(first.view), _terrain_signature(second.view), "known terrain matches")
	assert_eq(first.gold, second.gold, "gold matches")


func _known_unit_ids(view: PlayerView) -> Array:
	var entries: Array = []
	for unit: GameUnit in view.get_known_units():
		entries.append([unit.id, int(unit.owner), int(unit.type), unit.tile.x, unit.tile.y])
	return entries


func _terrain_signature(view: PlayerView) -> Array:
	var entries: Array = []
	for tile: Vector2i in view.board.get_playable_tiles():
		var data := view.board.get_tile(tile)
		entries.append([tile.x, tile.y, int(data.terrain), data.has_bridge])
	return entries


func _state_with_scout() -> GameState:
	var state := MovementTestUtils.empty_state()
	if state == null:
		return null
	MovementTestUtils.add_unit(state, UnitType.Type.SCOUT, PLAYER_1, CENTER)
	return state
