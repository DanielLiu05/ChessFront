class_name ActionResolver
extends RefCounted


static func validate(
	state: GameState,
	action: GameAction,
	_exploration: ExplorationProvider
) -> ActionResult:
	var result := ActionResult.new()
	if state.game_over:
		result.error = "Game is over"
		return result
	if action == null:
		result.error = "No action supplied"
		return result
	if action is MoveAction:
		return _validate_move(state, action as MoveAction)
	if action is BuildBridgeAction:
		return _validate_build_bridge(state, action as BuildBridgeAction)
	if action is DestroyBridgeAction:
		return _validate_destroy_bridge(state, action as DestroyBridgeAction)
	if action is RecruitAction:
		return _validate_recruit(state, action as RecruitAction)
	if action is PassAction:
		if TurnManager.pass_is_available(state):
			result.success = true
		else:
			result.error = "Pass is unavailable while a legal action exists"
		return result
	result.error = "Unsupported action"
	return result


static func resolve(
	state: GameState,
	action: GameAction,
	_exploration: ExplorationProvider
) -> ActionResult:
	var validation := validate(state, action, _exploration)
	if not validation.success:
		return validation

	if action is MoveAction:
		return _resolve_move(state, action as MoveAction)
	if action is BuildBridgeAction:
		return _resolve_build_bridge(state, action as BuildBridgeAction)
	if action is DestroyBridgeAction:
		return _resolve_destroy_bridge(state, action as DestroyBridgeAction)
	if action is RecruitAction:
		return _resolve_recruit(state, action as RecruitAction)

	var economy := EconomyReport.new()
	TurnManager.advance_turn(state)
	EconomySystem.advance_mines(state, economy)
	return _result_after_turn(state, economy)


static func _validate_move(state: GameState, action: MoveAction) -> ActionResult:
	var result := ActionResult.new()
	var unit := state.get_unit(action.unit_id)
	if unit == null:
		result.error = "Unit %d does not exist" % action.unit_id
		return result
	if unit.owner != state.active_player:
		result.error = "Unit %d does not belong to the active player" % unit.id
		return result
	var view := PlayerView.for_player(state, state.active_player)
	if not MovementRules.can_move_to(view, unit, action.destination, view.exploration):
		result.error = "Illegal destination for unit %d" % unit.id
		return result
	if (
		MovementRules.requires_promotion(unit, action.destination)
		and not MovementRules.is_valid_promotion_type(action.promotion_type)
	):
		result.error = "Invalid promotion choice"
		return result
	result.success = true
	return result


static func _resolve_move(state: GameState, action: MoveAction) -> ActionResult:
	var unit := state.get_unit(action.unit_id)
	var view := PlayerView.for_player(state, state.active_player)
	var commit := MoveCommit.from_view(view, action.unit_id, action.destination)
	var move_result := MoveExecutor.resolve(state, unit, commit, action.promotion_type)

	var result := ActionResult.new()
	result.move_result = move_result
	if not move_result.success:
		result.error = move_result.error
		return result

	result.success = true
	result.captured_unit = move_result.captured_unit
	result.moved = move_result.moved
	result.partial_move = move_result.partial
	result.ambushed = move_result.ambushed
	result.ambusher_type = move_result.ambusher_type
	result.ambusher_tile = move_result.ambusher_tile

	if result.captured_unit != null and result.captured_unit.type == UnitType.Type.KING:
		state.game_over = true
		state.winner = int(unit.owner)
		state.draw_offered_by = GameConfig.NO_PLAYER
		state.draw_reason = ""
		result.game_over = true
		result.winner = state.winner
		result.ply = state.ply
		result.active_player = int(state.active_player)
		return result

	var economy := EconomyReport.new()
	if not move_result.ambushed:
		var mover := state.get_unit(action.unit_id)
		if mover != null:
			EconomySystem.collect_token(state, mover, economy)
	state.refresh_vision()
	TurnManager.advance_turn(state)
	EconomySystem.advance_mines(state, economy)
	_populate_after_turn(result, state, economy)
	return result


static func _validate_build_bridge(state: GameState, action: BuildBridgeAction) -> ActionResult:
	var result := ActionResult.new()
	var unit := state.get_unit(action.engineer_id)
	if unit == null:
		result.error = "Unit %d does not exist" % action.engineer_id
		return result
	if unit.owner != state.active_player:
		result.error = "Unit %d does not belong to the active player" % unit.id
		return result
	if not BridgeRules.can_build(state, unit, action.target_tile):
		result.error = "Invalid bridge construction"
		return result
	result.success = true
	return result


static func _validate_destroy_bridge(state: GameState, action: DestroyBridgeAction) -> ActionResult:
	var result := ActionResult.new()
	var unit := state.get_unit(action.engineer_id)
	if unit == null:
		result.error = "Unit %d does not exist" % action.engineer_id
		return result
	if unit.owner != state.active_player:
		result.error = "Unit %d does not belong to the active player" % unit.id
		return result
	if not BridgeRules.can_destroy(state, unit, action.target_tile):
		result.error = "Invalid bridge destruction"
		return result
	result.success = true
	return result


static func _validate_recruit(state: GameState, action: RecruitAction) -> ActionResult:
	var result := ActionResult.new()
	if not (action.unit_type in UnitRegistry.get_all_types()):
		result.error = "Unknown unit type"
		return result
	var definition := UnitRegistry.get_definition(action.unit_type)
	if not definition.purchasable:
		result.error = "Unit type cannot be recruited"
		return result
	if state.get_gold(state.active_player) < definition.price:
		result.error = "Insufficient gold"
		return result
	if not RecruitmentRules.can_recruit(state, state.active_player, action.unit_type, action.spawn_tile):
		result.error = "Invalid deployment tile"
		return result
	result.success = true
	return result


static func _resolve_recruit(state: GameState, action: RecruitAction) -> ActionResult:
	var definition := UnitRegistry.get_definition(action.unit_type)
	var price := definition.price
	if not state.spend_gold(state.active_player, price):
		var failure := ActionResult.new()
		failure.error = "Insufficient gold"
		return failure

	var owner := state.active_player
	var unit := state.create_unit(action.unit_type, owner, action.spawn_tile)
	var economy := EconomyReport.new()
	state.refresh_vision()
	TurnManager.advance_turn(state)
	EconomySystem.advance_mines(state, economy)

	var result := _result_after_turn(state, economy)
	result.recruited_unit = unit
	result.gold_spent = price
	return result


static func _resolve_build_bridge(state: GameState, action: BuildBridgeAction) -> ActionResult:
	var data := state.board.get_tile(action.target_tile)
	data.has_bridge = true
	var economy := EconomyReport.new()
	state.refresh_vision()
	TurnManager.advance_turn(state)
	EconomySystem.advance_mines(state, economy)
	return _result_after_turn(state, economy)


static func _resolve_destroy_bridge(state: GameState, action: DestroyBridgeAction) -> ActionResult:
	var data := state.board.get_tile(action.target_tile)
	data.has_bridge = false
	var economy := EconomyReport.new()
	state.refresh_vision()
	TurnManager.advance_turn(state)
	EconomySystem.advance_mines(state, economy)
	return _result_after_turn(state, economy)


static func _result_after_turn(state: GameState, economy: EconomyReport) -> ActionResult:
	var result := ActionResult.new()
	result.success = true
	_populate_after_turn(result, state, economy)
	return result


static func _populate_after_turn(
	result: ActionResult,
	state: GameState,
	economy: EconomyReport
) -> void:
	DrawSystem.check_after_action(state)
	result.game_over = state.game_over
	result.winner = state.winner
	result.draw = state.draw_reason != ""
	result.draw_reason = state.draw_reason
	result.ply = state.ply
	result.active_player = int(state.active_player)
	for player: int in economy.gold_gained:
		result.gold_gained[player] = int(economy.gold_gained[player])
	for tile: Vector2i in economy.tokens_spawned:
		result.tokens_spawned.append(tile)
	for tile: Vector2i in economy.tokens_collected:
		result.tokens_collected.append(tile)
