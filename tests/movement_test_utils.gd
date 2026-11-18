class_name MovementTestUtils
extends RefCounted

const MAP_PATH: String = "res://maps/standard_template.json"


static func empty_state() -> GameState:
	var result := MapIO.load_from_file(MAP_PATH)
	if not result.is_valid():
		push_error("Could not load movement test map: %s" % str(result.errors))
		return null
	var state := GameState.new(result.map)
	clear_units(state)
	clear_gold(state)
	reset_knowledge(state)
	return state


static func clear_gold(state: GameState) -> void:
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		state.player_gold[player] = 0


static func clear_units(state: GameState) -> void:
	for unit: GameUnit in state.get_all_units():
		state.board.get_tile(unit.tile).occupant_id = BoardTileData.NO_OCCUPANT
	state.units.clear()
	state.occupancy.clear()


static func add_unit(
	state: GameState,
	unit_type: UnitType.Type,
	owner: GameConfig.Player,
	tile: Vector2i
) -> GameUnit:
	var next_id := 1
	for unit_id: int in state.units:
		next_id = maxi(next_id, unit_id + 1)
	var unit := GameUnit.new(next_id, unit_type, owner, tile)
	state.units[unit.id] = unit
	state.occupancy[tile] = unit.id
	state.board.get_tile(tile).occupant_id = unit.id
	return unit


static func relocate_unit(state: GameState, unit: GameUnit, tile: Vector2i) -> void:
	state.board.get_tile(unit.tile).occupant_id = BoardTileData.NO_OCCUPANT
	state.occupancy.erase(unit.tile)
	unit.tile = tile
	state.occupancy[tile] = unit.id
	state.board.get_tile(tile).occupant_id = unit.id


static func clear_knowledge(state: GameState) -> void:
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var knowledge := state.get_knowledge(player)
		knowledge.explored.clear()
		knowledge.visible.clear()
		knowledge.detected_enemy_ids.clear()


static func reset_knowledge(state: GameState) -> void:
	clear_knowledge(state)
	state.refresh_vision()
