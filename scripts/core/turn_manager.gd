class_name TurnManager
extends RefCounted


static func advance_turn(state: GameState) -> void:
	state.active_player = GameConfig.opponent(state.active_player)
	state.ply += 1


static func has_legal_move(
	state: MovementState,
	player: GameConfig.Player,
	exploration: ExplorationProvider
) -> bool:
	for unit: GameUnit in state.get_units_for_player(player):
		if not MovementRules.legal_destinations(state, unit, exploration).is_empty():
			return true
	return false


static func pass_is_available(state: GameState) -> bool:
	if state.game_over:
		return false
	var view := PlayerView.for_player(state, state.active_player)
	if has_legal_move(view, state.active_player, view.exploration):
		return false
	if RecruitmentRules.has_legal_recruitment(state, state.active_player):
		return false
	return not BridgeRules.has_legal_bridge_action(state, state.active_player)
