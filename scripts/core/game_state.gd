class_name GameState
extends MovementState

var units: Dictionary[int, GameUnit] = {}
var occupancy: Dictionary[Vector2i, int] = {}
var active_player: GameConfig.Player = GameConfig.FIRST_PLAYER
var ply: int = 0
var game_over: bool = false
var winner: int = GameConfig.NO_PLAYER
var map_id: String = ""
var map_format_version: int = MapData.FORMAT_VERSION
var gold_mines: Array[GoldMine] = []
var player_gold: Dictionary[int, int] = {}
var deployment_tiles: Dictionary[int, Array] = {}
var next_unit_id: int = 1
var turn_limit_plies: int = GameConfig.DEFAULT_TURN_LIMIT_PLIES
var draw_offered_by: int = GameConfig.NO_PLAYER
var draw_reason: String = ""
var position_counts: Dictionary[String, int] = {}
var knowledge: Dictionary[int, PlayerKnowledge] = {}
var _gold_mine_lookup: Dictionary[Vector2i, GoldMine] = {}


func _init(
	map: MapData,
	match_turn_limit_plies: int = GameConfig.DEFAULT_TURN_LIMIT_PLIES,
	first_player: int = GameConfig.FIRST_PLAYER
) -> void:
	board = map.board.duplicate_board()
	map_id = map.id
	map_format_version = map.format_version
	turn_limit_plies = match_turn_limit_plies
	active_player = first_player
	_initialize_gold()
	_store_deployment(map)
	_create_gold_mines(map)
	_deploy_units(map)
	_initialize_knowledge()
	DrawSystem.initialize(self)


func get_unit(unit_id: int) -> GameUnit:
	return units.get(unit_id) as GameUnit


func get_unit_at(tile: Vector2i) -> GameUnit:
	var unit_id: int = occupancy.get(tile, BoardTileData.NO_OCCUPANT)
	if unit_id == BoardTileData.NO_OCCUPANT:
		return null
	return units.get(unit_id) as GameUnit


func is_occupied(tile: Vector2i) -> bool:
	return occupancy.has(tile)


func get_all_units() -> Array[GameUnit]:
	var ids := units.keys()
	ids.sort()
	var result: Array[GameUnit] = []
	for unit_id: int in ids:
		result.append(units[unit_id])
	return result


func get_units_for_player(player: GameConfig.Player) -> Array[GameUnit]:
	var result: Array[GameUnit] = []
	for unit: GameUnit in get_all_units():
		if unit.owner == player:
			result.append(unit)
	return result


func count_units_for_player(player: GameConfig.Player) -> int:
	return get_units_for_player(player).size()


func get_gold_mine_at(tile: Vector2i) -> GoldMine:
	return _gold_mine_lookup.get(tile) as GoldMine


func get_mine_occupant(mine: GoldMine) -> GameUnit:
	return get_unit_at(mine.tile)


func get_mine_owner(mine: GoldMine) -> int:
	var unit := get_unit_at(mine.tile)
	if unit == null:
		return GameConfig.NO_PLAYER
	return int(unit.owner)


func get_gold(player: GameConfig.Player) -> int:
	return int(player_gold.get(player, 0))


func add_gold(player: GameConfig.Player, amount: int) -> void:
	if amount <= 0:
		return
	player_gold[player] = get_gold(player) + amount


func spend_gold(player: GameConfig.Player, amount: int) -> bool:
	if amount < 0:
		return false
	var current := get_gold(player)
	if current < amount:
		return false
	player_gold[player] = current - amount
	return true


func get_deployment_tiles(player: GameConfig.Player) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var raw: Array = deployment_tiles.get(player, [])
	for tile: Vector2i in raw:
		tiles.append(tile)
	return tiles


func is_deployment_tile(player: GameConfig.Player, tile: Vector2i) -> bool:
	for candidate: Vector2i in get_deployment_tiles(player):
		if candidate == tile:
			return true
	return false


func allocate_unit_id() -> int:
	var unit_id := next_unit_id
	next_unit_id += 1
	return unit_id


func create_unit(unit_type: int, owner: GameConfig.Player, tile: Vector2i) -> GameUnit:
	var unit := GameUnit.new(allocate_unit_id(), unit_type, owner, tile)
	units[unit.id] = unit
	occupancy[tile] = unit.id
	board.get_tile(tile).occupant_id = unit.id
	return unit


func get_knowledge(player: GameConfig.Player) -> PlayerKnowledge:
	return knowledge.get(player) as PlayerKnowledge


func refresh_vision() -> void:
	VisionSystem.recompute(board, get_all_units(), knowledge)


func is_gold_mine(tile: Vector2i) -> bool:
	return _gold_mine_lookup.has(tile)


func get_bridge_tiles() -> Array[Vector2i]:
	var bridges: Array[Vector2i] = []
	for tile: Vector2i in board.get_playable_tiles():
		if board.get_tile(tile).has_bridge:
			bridges.append(tile)
	return bridges


func snapshot() -> Dictionary:
	var unit_entries: Array = []
	for unit: GameUnit in get_all_units():
		unit_entries.append({
			"id": unit.id,
			"type": int(unit.type),
			"owner": int(unit.owner),
			"tile": [unit.tile.x, unit.tile.y],
		})
	var mine_entries: Array = []
	for mine: GoldMine in gold_mines:
		mine_entries.append({
			"tile": [mine.tile.x, mine.tile.y],
			"cycle_progress": mine.cycle_progress,
			"gold_available": mine.gold_available,
		})
	var gold_entries: Dictionary = {
		"player_1": get_gold(GameConfig.Player.PLAYER_1),
		"player_2": get_gold(GameConfig.Player.PLAYER_2),
	}
	var bridge_entries: Array = []
	for tile: Vector2i in get_bridge_tiles():
		bridge_entries.append([tile.x, tile.y])
	var knowledge_entries: Dictionary = {}
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var key := "player_1" if player == GameConfig.Player.PLAYER_1 else "player_2"
		knowledge_entries[key] = get_knowledge(player).to_snapshot()
	return {
		"map_id": map_id,
		"map_format_version": map_format_version,
		"active_player": int(active_player),
		"ply": ply,
		"game_over": game_over,
		"winner": winner,
		"turn_limit_plies": turn_limit_plies,
		"draw_offered_by": draw_offered_by,
		"draw_reason": draw_reason,
		"player_gold": gold_entries,
		"gold_mines": mine_entries,
		"bridges": bridge_entries,
		"knowledge": knowledge_entries,
		"units": unit_entries,
	}


func snapshot_text() -> String:
	return JSON.stringify(snapshot(), "", true)


func _create_gold_mines(map: MapData) -> void:
	var tiles: Array[Vector2i] = []
	for tile: Vector2i in map.gold_mines:
		tiles.append(tile)
	tiles.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			if a.y != b.y:
				return a.y < b.y
			return a.x < b.x
	)
	for tile: Vector2i in tiles:
		var mine := GoldMine.new(tile)
		gold_mines.append(mine)
		_gold_mine_lookup[tile] = mine


func _initialize_gold() -> void:
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		player_gold[player] = 0


func _store_deployment(map: MapData) -> void:
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		deployment_tiles[player] = map.get_deployment_tiles(player)


func _initialize_knowledge() -> void:
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		knowledge[player] = PlayerKnowledge.new(player)
	VisionSystem.recompute(board, get_all_units(), knowledge)


func _deploy_units(map: MapData) -> void:
	var next_id := 1
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var starting_units := map.get_starting_units(player)
		starting_units.sort_custom(
			func(a: MapStartingUnit, b: MapStartingUnit) -> bool:
				if a.tile.y != b.tile.y:
					return a.tile.y < b.tile.y
				return a.tile.x < b.tile.x
		)
		for starting_unit: MapStartingUnit in starting_units:
			var unit := GameUnit.new(next_id, starting_unit.type, player, starting_unit.tile)
			units[next_id] = unit
			occupancy[starting_unit.tile] = next_id
			var tile := board.get_tile(starting_unit.tile)
			tile.occupant_id = next_id
			next_id += 1
	next_unit_id = next_id
