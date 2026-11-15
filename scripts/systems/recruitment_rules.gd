class_name RecruitmentRules
extends RefCounted


static func can_recruit(
	state: GameState,
	player: GameConfig.Player,
	unit_type: int,
	tile: Vector2i
) -> bool:
	if not (unit_type in UnitRegistry.get_all_types()):
		return false
	var definition := UnitRegistry.get_definition(unit_type)
	if not definition.purchasable:
		return false
	if state.get_gold(player) < definition.price:
		return false
	if not state.is_deployment_tile(player, tile):
		return false
	if not state.board.is_playable(tile) or not state.board.is_passable(tile):
		return false
	return not state.is_occupied(tile)


static func available_spawn_tiles(
	state: GameState,
	player: GameConfig.Player
) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile: Vector2i in state.get_deployment_tiles(player):
		if not state.board.is_playable(tile) or not state.board.is_passable(tile):
			continue
		if state.is_occupied(tile):
			continue
		tiles.append(tile)
	return tiles


static func has_legal_recruitment(state: GameState, player: GameConfig.Player) -> bool:
	if available_spawn_tiles(state, player).is_empty():
		return false
	var gold := state.get_gold(player)
	for unit_type: int in UnitRegistry.get_all_types():
		var definition := UnitRegistry.get_definition(unit_type)
		if definition.purchasable and definition.price <= gold:
			return true
	return false
