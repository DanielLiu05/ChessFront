class_name MovementRules
extends RefCounted

const ORTHOGONAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
]
const DIAGONAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(1, 1),
]
const KNIGHT_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -2),
	Vector2i(-2, -1),
	Vector2i(-2, 1),
	Vector2i(-1, 2),
	Vector2i(1, 2),
	Vector2i(2, 1),
	Vector2i(2, -1),
	Vector2i(1, -2),
]


static func legal_destinations(
	state: MovementState,
	unit: GameUnit,
	exploration: ExplorationProvider
) -> Array[Vector2i]:
	var category: UnitDefinition.MovementCategory = unit.definition().movement_category
	match category:
		UnitDefinition.MovementCategory.SINGLE:
			return _single_tile_destinations(state, unit, BoardData.DIRECTIONS)
		UnitDefinition.MovementCategory.RAY:
			return _ray_destinations(state, unit, _ray_directions(unit.type), exploration)
		UnitDefinition.MovementCategory.JUMP:
			return _jump_destinations(state, unit)
		UnitDefinition.MovementCategory.STEP:
			if unit.type == UnitType.Type.PAWN:
				return _pawn_destinations(state, unit)
			if unit.type == UnitType.Type.SCOUT:
				return _scout_destinations(state, unit, BoardData.DIRECTIONS, exploration)
			return _step_destinations(state, unit, BoardData.DIRECTIONS, exploration)
	return []


static func can_move_to(
	state: MovementState,
	unit: GameUnit,
	destination: Vector2i,
	exploration: ExplorationProvider
) -> bool:
	return destination in legal_destinations(state, unit, exploration)


static func move_unit(
	state: GameState,
	unit: GameUnit,
	destination: Vector2i,
	exploration: ExplorationProvider,
	promotion_type: int = UnitType.Type.QUEEN
) -> MoveResult:
	var result := MoveResult.new()
	result.unit_id = unit.id
	result.from_tile = unit.tile
	result.to_tile = destination

	if not can_move_to(state, unit, destination, exploration):
		result.error = "Illegal destination for unit %d" % unit.id
		return result

	var promotion_applies := requires_promotion(unit, destination)
	if promotion_applies and not is_valid_promotion_type(promotion_type):
		result.error = "Invalid promotion choice"
		return result

	var captured := state.get_unit_at(destination)
	if captured != null:
		result.captured_unit = captured
		state.units.erase(captured.id)
		state.occupancy.erase(destination)

	state.board.get_tile(unit.tile).occupant_id = BoardTileData.NO_OCCUPANT
	state.occupancy.erase(unit.tile)
	unit.tile = destination
	state.units[unit.id] = unit
	state.occupancy[destination] = unit.id
	state.board.get_tile(destination).occupant_id = unit.id

	if promotion_applies:
		unit.type = promotion_type
		result.promoted_to = promotion_type

	result.success = true
	return result


static func _single_tile_destinations(
	state: MovementState,
	unit: GameUnit,
	directions: Array[Vector2i]
) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	for direction: Vector2i in directions:
		var destination := unit.tile + direction
		if not state.board.is_passable(destination):
			continue
		var occupant := state.get_unit_at(destination)
		if occupant == null:
			destinations.append(destination)
		elif occupant.owner != unit.owner and unit.definition().can_capture:
			destinations.append(destination)
	return destinations


static func _ray_destinations(
	state: MovementState,
	unit: GameUnit,
	directions: Array[Vector2i],
	exploration: ExplorationProvider
) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	var can_capture := unit.definition().can_capture
	for direction: Vector2i in directions:
		var tile := unit.tile
		while true:
			tile += direction
			if not state.board.is_playable(tile):
				break
			if not exploration.is_explored(tile):
				break
			if not state.board.is_passable(tile):
				break
			var occupant := state.get_unit_at(tile)
			if occupant == null:
				destinations.append(tile)
				continue
			if occupant.owner != unit.owner and can_capture:
				destinations.append(tile)
			break
	return destinations


static func _jump_destinations(state: MovementState, unit: GameUnit) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	for offset: Vector2i in KNIGHT_OFFSETS:
		var destination := unit.tile + offset
		if not state.board.is_passable(destination):
			continue
		var occupant := state.get_unit_at(destination)
		if occupant == null:
			destinations.append(destination)
		elif occupant.owner != unit.owner and unit.definition().can_capture:
			destinations.append(destination)
	return destinations


static func _pawn_destinations(state: MovementState, unit: GameUnit) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	var forward := Vector2i(0, GameConfig.forward_row_delta(unit.owner))

	var one_step := unit.tile + forward
	if state.board.is_passable(one_step) and not state.is_occupied(one_step):
		destinations.append(one_step)
		var two_steps := one_step + forward
		if state.board.is_passable(two_steps) and not state.is_occupied(two_steps):
			destinations.append(two_steps)

	for side: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0)]:
		var capture_tile := unit.tile + forward + side
		if not state.board.is_passable(capture_tile):
			continue
		var occupant := state.get_unit_at(capture_tile)
		if occupant != null and occupant.owner != unit.owner:
			destinations.append(capture_tile)
	return destinations


static func _step_destinations(
	state: MovementState,
	unit: GameUnit,
	directions: Array[Vector2i],
	exploration: ExplorationProvider
) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	var definition := unit.definition()
	for direction: Vector2i in directions:
		var tile := unit.tile
		var all_path_explored := true
		for distance in range(1, definition.explored_reach + 1):
			tile += direction
			if not state.board.is_passable(tile):
				break
			all_path_explored = all_path_explored and exploration.is_explored(tile)
			if state.is_occupied(tile):
				break
			if distance <= definition.base_reach or all_path_explored:
				destinations.append(tile)
	return destinations


static func _scout_destinations(
	state: MovementState,
	unit: GameUnit,
	directions: Array[Vector2i],
	exploration: ExplorationProvider
) -> Array[Vector2i]:
	var destinations: Array[Vector2i] = []
	if _is_unbridged_water(state.board, unit.tile):
		for direction: Vector2i in directions:
			var destination := unit.tile + direction
			if not state.board.is_playable(destination):
				continue
			if state.is_occupied(destination):
				continue
			destinations.append(destination)
		return destinations

	var definition := unit.definition()
	for direction: Vector2i in directions:
		var tile := unit.tile
		var all_path_explored := true
		for distance in range(1, definition.explored_reach + 1):
			tile += direction
			if not state.board.is_playable(tile):
				break
			var unbridged_water := _is_unbridged_water(state.board, tile)
			if unbridged_water and distance > 1:
				break
			if not unbridged_water and not state.board.is_passable(tile):
				break
			all_path_explored = all_path_explored and exploration.is_explored(tile)
			if state.is_occupied(tile):
				break
			if distance <= definition.base_reach or all_path_explored:
				destinations.append(tile)
			if unbridged_water:
				break
	return destinations


static func _is_unbridged_water(board: BoardData, tile: Vector2i) -> bool:
	var data := board.get_tile(tile)
	return data != null and data.terrain == TerrainType.Type.WATER and not data.has_bridge


static func _ray_directions(unit_type: int) -> Array[Vector2i]:
	match unit_type:
		UnitType.Type.ROOK:
			return ORTHOGONAL_DIRECTIONS
		UnitType.Type.BISHOP:
			return DIAGONAL_DIRECTIONS
		_:
			return BoardData.DIRECTIONS


static func requires_promotion(unit: GameUnit, destination: Vector2i) -> bool:
	return (
		unit.type == UnitType.Type.PAWN
		and destination.y == GameConfig.promotion_row(unit.owner)
	)


static func is_valid_promotion_type(promotion_type: int) -> bool:
	return promotion_type in [
		UnitType.Type.QUEEN,
		UnitType.Type.ROOK,
		UnitType.Type.BISHOP,
		UnitType.Type.KNIGHT,
	]
