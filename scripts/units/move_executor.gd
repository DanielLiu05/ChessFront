class_name MoveExecutor
extends RefCounted


static func resolve(
	state: GameState,
	unit: GameUnit,
	commit: MoveCommit,
	promotion_type: int = UnitType.Type.QUEEN
) -> MoveResult:
	var result := MoveResult.new()
	result.unit_id = unit.id
	result.from_tile = unit.tile
	result.to_tile = commit.destination
	result.final_tile = unit.tile

	var category: UnitDefinition.MovementCategory = unit.definition().movement_category
	match category:
		UnitDefinition.MovementCategory.RAY:
			_resolve_ray(state, unit, commit, result)
		UnitDefinition.MovementCategory.STEP:
			_resolve_step(state, unit, commit, promotion_type, result)
		UnitDefinition.MovementCategory.JUMP:
			_resolve_destination(state, unit, commit, result)
		UnitDefinition.MovementCategory.SINGLE:
			_resolve_destination(state, unit, commit, result)
		_:
			result.error = "Unsupported movement category"
	if result.error.is_empty():
		result.success = true
	return result


static func _resolve_ray(
	state: GameState,
	unit: GameUnit,
	commit: MoveCommit,
	result: MoveResult
) -> void:
	var delta := commit.destination - unit.tile
	if not _is_valid_ray_direction(unit.type, delta):
		result.error = "Invalid ray destination"
		return
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var distance := maxi(absi(delta.x), absi(delta.y))
	var final := unit.tile
	for step in range(1, distance + 1):
		var tile := unit.tile + direction * step
		if not commit.exploration.is_explored(tile):
			break
		if not state.board.is_passable(tile):
			break
		var occupant := state.get_unit_at(tile)
		if occupant == null:
			final = tile
			continue
		if occupant.owner == unit.owner:
			break
		_capture(state, occupant, result)
		final = tile
		break
	_finish_move(state, unit, final, commit.destination, result)


static func _resolve_destination(
	state: GameState,
	unit: GameUnit,
	commit: MoveCommit,
	result: MoveResult
) -> void:
	var destination := commit.destination
	if not state.board.is_passable(destination):
		return
	var occupant := state.get_unit_at(destination)
	if occupant != null:
		if occupant.owner == unit.owner:
			return
		_capture(state, occupant, result)
	_finish_move(state, unit, destination, destination, result)


static func _resolve_step(
	state: GameState,
	unit: GameUnit,
	commit: MoveCommit,
	promotion_type: int,
	result: MoveResult
) -> void:
	var delta := commit.destination - unit.tile
	if not _is_straight_delta(delta):
		result.error = "Invalid step destination"
		return
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var distance := maxi(absi(delta.x), absi(delta.y))
	var final := unit.tile
	match unit.type:
		UnitType.Type.PAWN:
			final = _pawn_step_final(state, unit, commit, delta, result)
		UnitType.Type.SCOUT:
			final = _scout_step_final(state, unit, commit, direction, distance, result)
		UnitType.Type.ENGINEER:
			final = _engineer_step_final(state, unit, commit, direction, distance, result)
		_:
			result.error = "Unsupported step unit"
			return
	if result.ambushed:
		return
	_finish_step(state, unit, final, commit.destination, promotion_type, result)


static func _pawn_step_final(
	state: GameState,
	unit: GameUnit,
	commit: MoveCommit,
	delta: Vector2i,
	result: MoveResult
) -> Vector2i:
	var forward := GameConfig.forward_row_delta(unit.owner)
	if absi(delta.x) == 1 and delta.y == forward:
		var target := state.get_unit_at(commit.destination)
		if (
			target != null
			and target.owner != unit.owner
			and commit.detected_enemy_ids.has(target.id)
		):
			_capture(state, target, result)
			return commit.destination
		return unit.tile

	if delta.x != 0 or (delta.y != forward and delta.y != forward * 2):
		result.error = "Invalid pawn direction"
		return unit.tile

	var distance := absi(delta.y)
	var final := unit.tile
	for step in range(1, distance + 1):
		var tile := unit.tile + Vector2i(0, forward * step)
		if not state.board.is_passable(tile):
			break
		var occupant := state.get_unit_at(tile)
		if occupant == null:
			final = tile
			continue
		if occupant.owner == unit.owner:
			break
		if (
			not commit.detected_enemy_ids.has(occupant.id)
			and occupant.definition().can_capture
		):
			_ambush(state, unit, occupant, result)
			return unit.tile
		break
	return final


static func _scout_step_final(
	state: GameState,
	unit: GameUnit,
	commit: MoveCommit,
	direction: Vector2i,
	distance: int,
	result: MoveResult
) -> Vector2i:
	if _is_unbridged_water(state.board, unit.tile):
		if distance != 1:
			return unit.tile
		var water_exit := unit.tile + direction
		if not state.board.is_playable(water_exit):
			return unit.tile
		var exit_occupant := state.get_unit_at(water_exit)
		if exit_occupant == null:
			return water_exit
		if exit_occupant.owner == unit.owner:
			return unit.tile
		if (
			not commit.detected_enemy_ids.has(exit_occupant.id)
			and exit_occupant.definition().can_capture
		):
			_ambush(state, unit, exit_occupant, result)
		return unit.tile

	var final := unit.tile
	for step in range(1, distance + 1):
		var tile := unit.tile + direction * step
		if not state.board.is_playable(tile):
			break
		var unbridged := _is_unbridged_water(state.board, tile)
		if unbridged:
			if step > 1 or distance > 1:
				break
		elif not state.board.is_passable(tile):
			break
		var occupant := state.get_unit_at(tile)
		if occupant == null:
			final = tile
			if unbridged:
				break
			continue
		if occupant.owner == unit.owner:
			break
		if (
			not commit.detected_enemy_ids.has(occupant.id)
			and occupant.definition().can_capture
		):
			_ambush(state, unit, occupant, result)
			return unit.tile
		break
	return final


static func _engineer_step_final(
	state: GameState,
	unit: GameUnit,
	commit: MoveCommit,
	direction: Vector2i,
	distance: int,
	result: MoveResult
) -> Vector2i:
	var final := unit.tile
	for step in range(1, distance + 1):
		var tile := unit.tile + direction * step
		if not state.board.is_passable(tile):
			break
		var occupant := state.get_unit_at(tile)
		if occupant == null:
			final = tile
			continue
		if occupant.owner == unit.owner:
			break
		if (
			not commit.detected_enemy_ids.has(occupant.id)
			and occupant.definition().can_capture
		):
			_ambush(state, unit, occupant, result)
			return unit.tile
		break
	return final


static func _finish_move(
	state: GameState,
	unit: GameUnit,
	final: Vector2i,
	destination: Vector2i,
	result: MoveResult
) -> void:
	result.final_tile = final
	if final == unit.tile:
		return
	_move_unit_to(state, unit, final)
	result.moved = true
	result.partial = final != destination


static func _finish_step(
	state: GameState,
	unit: GameUnit,
	final: Vector2i,
	destination: Vector2i,
	promotion_type: int,
	result: MoveResult
) -> void:
	result.final_tile = final
	if final == unit.tile:
		return
	_move_unit_to(state, unit, final)
	result.moved = true
	result.partial = final != destination
	if unit.type == UnitType.Type.PAWN and final.y == GameConfig.promotion_row(unit.owner):
		unit.type = promotion_type
		result.promoted_to = promotion_type


static func _capture(state: GameState, target: GameUnit, result: MoveResult) -> void:
	result.captured_unit = target
	state.units.erase(target.id)
	state.occupancy.erase(target.tile)
	state.board.get_tile(target.tile).occupant_id = BoardTileData.NO_OCCUPANT


static func _ambush(state: GameState, mover: GameUnit, ambusher: GameUnit, result: MoveResult) -> void:
	var mover_tile := mover.tile
	state.units.erase(mover.id)
	state.occupancy.erase(mover.tile)
	state.board.get_tile(mover.tile).occupant_id = BoardTileData.NO_OCCUPANT
	result.ambushed = true
	result.ambusher_type = int(ambusher.type)
	result.ambusher_tile = ambusher.tile
	result.final_tile = mover_tile
	result.moved = false
	result.partial = false


static func _move_unit_to(state: GameState, unit: GameUnit, tile: Vector2i) -> void:
	state.board.get_tile(unit.tile).occupant_id = BoardTileData.NO_OCCUPANT
	state.occupancy.erase(unit.tile)
	unit.tile = tile
	state.occupancy[tile] = unit.id
	state.board.get_tile(tile).occupant_id = unit.id


static func _is_valid_ray_direction(unit_type: int, delta: Vector2i) -> bool:
	match unit_type:
		UnitType.Type.ROOK:
			return delta.x == 0 or delta.y == 0
		UnitType.Type.BISHOP:
			return absi(delta.x) == absi(delta.y)
		UnitType.Type.QUEEN:
			return delta.x == 0 or delta.y == 0 or absi(delta.x) == absi(delta.y)
		_:
			return false


static func _is_straight_delta(delta: Vector2i) -> bool:
	return delta != Vector2i.ZERO and (
		delta.x == 0 or delta.y == 0 or absi(delta.x) == absi(delta.y)
	)


static func _is_unbridged_water(board: BoardData, tile: Vector2i) -> bool:
	var data := board.get_tile(tile)
	return data != null and data.terrain == TerrainType.Type.WATER and not data.has_bridge
