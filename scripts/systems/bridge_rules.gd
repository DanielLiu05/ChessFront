class_name BridgeRules
extends RefCounted


static func can_build(state: MovementState, unit: GameUnit, target: Vector2i) -> bool:
	if not unit.definition().has_ability(UnitDefinition.Ability.BUILD_BRIDGES):
		return false
	if not _is_adjacent(unit.tile, target):
		return false
	if not state.board.is_playable(target):
		return false
	var data := state.board.get_tile(target)
	if data.terrain != TerrainType.Type.WATER or data.has_bridge:
		return false
	return not state.is_occupied(target)


static func can_destroy(state: MovementState, unit: GameUnit, target: Vector2i) -> bool:
	if not unit.definition().has_ability(UnitDefinition.Ability.BUILD_BRIDGES):
		return false
	if not _is_adjacent(unit.tile, target):
		return false
	if not state.board.is_playable(target):
		return false
	var data := state.board.get_tile(target)
	if not data.has_bridge:
		return false
	return not state.is_occupied(target)


static func has_legal_bridge_action(state: MovementState, player: GameConfig.Player) -> bool:
	for unit: GameUnit in state.get_units_for_player(player):
		if not unit.definition().has_ability(UnitDefinition.Ability.BUILD_BRIDGES):
			continue
		for direction: Vector2i in BoardData.DIRECTIONS:
			var target := unit.tile + direction
			if can_build(state, unit, target) or can_destroy(state, unit, target):
				return true
	return false


static func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return maxi(absi(a.x - b.x), absi(a.y - b.y)) == 1
