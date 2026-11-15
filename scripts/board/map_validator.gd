class_name MapValidator
extends RefCounted

const EXPECTED_STARTING_COUNTS: Dictionary[int, int] = {
	UnitType.Type.KING: 1,
	UnitType.Type.QUEEN: 1,
	UnitType.Type.ROOK: 2,
	UnitType.Type.BISHOP: 2,
	UnitType.Type.KNIGHT: 2,
	UnitType.Type.PAWN: 8,
	UnitType.Type.SCOUT: 0,
	UnitType.Type.ENGINEER: 0,
}

const CENTRAL_BAND_ROWS: Vector2i = Vector2i(6, 9)


static func validate(map: MapData) -> Array[String]:
	return _messages(validate_issues(map, false))


static func validate_for_match(map: MapData) -> Array[String]:
	return _messages(validate_issues(map, true))


static func validate_issues(map: MapData, for_match: bool = false) -> Array[MapValidationIssue]:
	var issues: Array[MapValidationIssue] = []
	_validate_mask_and_terrain(map, issues)
	if not issues.is_empty():
		return issues
	_validate_mines(map, issues)
	if not issues.is_empty():
		return issues
	_validate_deployment(map, issues)
	if not issues.is_empty():
		return issues
	_validate_starting_units(map, issues)
	if not issues.is_empty():
		return issues
	_validate_first_turn_captures(map, issues)
	if for_match and issues.is_empty():
		_validate_match_accessibility(map, issues)
	return issues


static func derived_deployment_tiles(board: BoardData, player: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var row_range := GameConfig.deployment_row_range(player)
	for row in range(row_range.x, row_range.y + 1):
		for column in GameConfig.BOARD_WIDTH:
			var tile := Vector2i(column, row)
			if board.is_playable(tile):
				tiles.append(tile)
	return tiles


static func _messages(issues: Array[MapValidationIssue]) -> Array[String]:
	var messages: Array[String] = []
	for issue: MapValidationIssue in issues:
		messages.append(issue.message)
	return messages


static func _add(
	issues: Array[MapValidationIssue],
	message: String,
	tiles: Array = []
) -> void:
	issues.append(MapValidationIssue.new(message, tiles))


static func _validate_mask_and_terrain(
	map: MapData,
	issues: Array[MapValidationIssue]
) -> void:
	for row in GameConfig.BOARD_HEIGHT:
		for column in GameConfig.BOARD_WIDTH:
			var tile := Vector2i(column, row)
			var mirror := GameConfig.mirror_tile(tile)
			var source := map.board.get_tile(tile)
			var counterpart := map.board.get_tile(mirror)
			if (source == null) != (counterpart == null):
				_add(
					issues,
					"Board mask is not point-symmetric at %s" % str(tile),
					[tile, mirror]
				)
				return
			if source == null:
				continue
			if source.terrain != counterpart.terrain:
				_add(
					issues,
					"Terrain at %s does not match its mirror at %s" % [str(tile), str(mirror)],
					[tile, mirror]
				)
				return
			if source.elevation != counterpart.elevation:
				_add(
					issues,
					"Elevation at %s does not match its mirror at %s" % [str(tile), str(mirror)],
					[tile, mirror]
				)
				return


static func _validate_mines(map: MapData, issues: Array[MapValidationIssue]) -> void:
	var mine_tiles: Dictionary[Vector2i, bool] = {}
	for tile: Vector2i in map.gold_mines:
		if not map.board.is_playable(tile):
			_add(issues, "Gold mine at %s is not playable" % str(tile), [tile])
			return
		if not map.board.is_passable(tile):
			_add(issues, "Gold mine at %s is not passable" % str(tile), [tile])
			return
		if mine_tiles.has(tile):
			_add(issues, "Duplicate gold mine at %s" % str(tile), [tile])
			return
		mine_tiles[tile] = true
	for tile: Vector2i in map.gold_mines:
		if not mine_tiles.has(GameConfig.mirror_tile(tile)):
			_add(
				issues,
				"Gold mine at %s has no point-symmetric counterpart" % str(tile),
				[tile, GameConfig.mirror_tile(tile)]
			)
			return


static func _validate_deployment(map: MapData, issues: Array[MapValidationIssue]) -> void:
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var tiles := map.get_deployment_tiles(player)
		var seen: Dictionary[Vector2i, bool] = {}
		var row_range := GameConfig.deployment_row_range(player)
		for tile: Vector2i in tiles:
			if not map.board.is_playable(tile):
				_add(
					issues,
					"Deployment tile %s for player %d is not playable" % [str(tile), player],
					[tile]
				)
				return
			if not map.board.is_passable(tile):
				_add(
					issues,
					"Deployment tile %s for player %d is not passable" % [str(tile), player],
					[tile]
				)
				return
			if tile.y < row_range.x or tile.y > row_range.y:
				_add(
					issues,
					"Deployment tile %s for player %d is outside rows %d-%d"
					% [str(tile), player, row_range.x, row_range.y],
					[tile]
				)
				return
			if seen.has(tile):
				_add(
					issues,
					"Duplicate deployment tile %s for player %d" % [str(tile), player],
					[tile]
				)
				return
			seen[tile] = true
		var expected := derived_deployment_tiles(map.board, player)
		if not _same_tile_set(tiles, expected):
			var affected := _tiles_not_in(expected, tiles)
			affected.append_array(_tiles_not_in(tiles, expected))
			_add(
				issues,
				"Deployment area for player %d must contain every playable tile in rows %d-%d"
				% [player, row_range.x, row_range.y],
				affected
			)
			return
	var p1_tiles := map.get_deployment_tiles(GameConfig.Player.PLAYER_1)
	var p2_tiles := map.get_deployment_tiles(GameConfig.Player.PLAYER_2)
	var mirrored_p2 := _mirror_tiles(p2_tiles)
	if not _same_tile_set(p1_tiles, mirrored_p2):
		var affected := _tiles_not_in(p1_tiles, mirrored_p2)
		affected.append_array(_tiles_not_in(mirrored_p2, p1_tiles))
		_add(issues, "Deployment areas are not point-symmetric", affected)


static func _validate_starting_units(
	map: MapData,
	issues: Array[MapValidationIssue]
) -> void:
	var all_tiles: Dictionary[Vector2i, bool] = {}
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var units := map.get_starting_units(player)
		if units.size() != 16:
			_add(issues, "Player %d must start with exactly 16 units" % player)
			return
		var type_counts: Dictionary[int, int] = {}
		for unit: MapStartingUnit in units:
			if not map.board.is_playable(unit.tile):
				_add(
					issues,
					"Starting unit at %s for player %d is not playable" % [str(unit.tile), player],
					[unit.tile]
				)
				return
			if not map.board.is_passable(unit.tile):
				_add(
					issues,
					"Starting unit at %s for player %d is not passable" % [str(unit.tile), player],
					[unit.tile]
				)
				return
			if not GameConfig.is_in_home_half(player, unit.tile.y):
				_add(
					issues,
					"Starting unit at %s for player %d is outside its home half"
					% [str(unit.tile), player],
					[unit.tile]
				)
				return
			if all_tiles.has(unit.tile):
				_add(issues, "Two starting units share tile %s" % str(unit.tile), [unit.tile])
				return
			all_tiles[unit.tile] = true
			type_counts[unit.type] = int(type_counts.get(unit.type, 0)) + 1
		for unit_type: int in EXPECTED_STARTING_COUNTS:
			var expected: int = EXPECTED_STARTING_COUNTS[unit_type]
			var actual: int = int(type_counts.get(unit_type, 0))
			if actual != expected:
				_add(
					issues,
					"Player %d has %d of unit type %d; expected %d"
					% [player, actual, unit_type, expected]
				)
				return
	_validate_starting_symmetry(map, issues)


static func _validate_starting_symmetry(
	map: MapData,
	issues: Array[MapValidationIssue]
) -> void:
	var p2_lookup: Dictionary[String, bool] = {}
	for unit: MapStartingUnit in map.get_starting_units(GameConfig.Player.PLAYER_2):
		p2_lookup[_unit_key(unit.type, unit.tile)] = true
	for unit: MapStartingUnit in map.get_starting_units(GameConfig.Player.PLAYER_1):
		var mirror := GameConfig.mirror_tile(unit.tile)
		if not p2_lookup.has(_unit_key(unit.type, mirror)):
			var unit_name: String = UnitRegistry.get_definition(unit.type).display_name
			_add(
				issues,
				"Starting layout is not point-symmetric: player 2 has no %s at %s"
				% [unit_name, str(mirror)],
				[unit.tile, mirror]
			)
			return


static func _validate_first_turn_captures(
	map: MapData,
	issues: Array[MapValidationIssue]
) -> void:
	var state := GameState.new(map)
	var exploration := ExplorationProvider.all_explored()
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		for unit: GameUnit in state.get_units_for_player(player):
			for destination: Vector2i in MovementRules.legal_destinations(state, unit, exploration):
				var target := state.get_unit_at(destination)
				if target != null and target.owner != unit.owner:
					_add(
						issues,
						"First-turn capture available: player %d %s at %s can capture %s at %s"
						% [
							player,
							UnitRegistry.get_definition(unit.type).display_name,
							str(unit.tile),
							UnitRegistry.get_definition(target.type).display_name,
							str(target.tile),
						],
						[unit.tile, target.tile]
					)
					return


static func _validate_match_accessibility(
	map: MapData,
	issues: Array[MapValidationIssue]
) -> void:
	var p1_reachable := _reachable_land_tiles(map, GameConfig.Player.PLAYER_1)
	var p2_reachable := _reachable_land_tiles(map, GameConfig.Player.PLAYER_2)
	var shared_mines: Array[Vector2i] = []
	for mine_tile: Vector2i in map.gold_mines:
		if p1_reachable.has(mine_tile) and p2_reachable.has(mine_tile):
			shared_mines.append(mine_tile)
	if shared_mines.size() < 2:
		var affected: Array[Vector2i] = []
		for mine_tile: Vector2i in map.gold_mines:
			affected.append(mine_tile)
		_add(
			issues,
			"Map must have at least two shared gold mines reachable by ordinary units; found %d"
			% shared_mines.size(),
			affected
		)
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var reachable := p1_reachable if player == GameConfig.Player.PLAYER_1 else p2_reachable
		if not _reaches_central_band(reachable):
			_add(
				issues,
				"Player %d deployment area cannot reach the central battlefield rows %d-%d"
				% [player, CENTRAL_BAND_ROWS.x, CENTRAL_BAND_ROWS.y],
				map.get_deployment_tiles(player)
			)


static func _reachable_land_tiles(map: MapData, player: int) -> Dictionary[Vector2i, bool]:
	var reachable: Dictionary[Vector2i, bool] = {}
	var frontier: Array[Vector2i] = []
	for tile: Vector2i in map.get_deployment_tiles(player):
		if not _is_land_traversable(map, tile) or reachable.has(tile):
			continue
		reachable[tile] = true
		frontier.append(tile)
	var index := 0
	while index < frontier.size():
		var current: Vector2i = frontier[index]
		index += 1
		for neighbor: Vector2i in map.board.get_neighbors(current):
			if reachable.has(neighbor) or not _is_land_traversable(map, neighbor):
				continue
			reachable[neighbor] = true
			frontier.append(neighbor)
	return reachable


static func _is_land_traversable(map: MapData, tile: Vector2i) -> bool:
	if not map.board.is_playable(tile):
		return false
	var data := map.board.get_tile(tile)
	if data == null:
		return false
	return not TerrainRegistry.get_definition(data.terrain).is_water


static func _reaches_central_band(reachable: Dictionary[Vector2i, bool]) -> bool:
	for tile: Vector2i in reachable:
		if tile.y >= CENTRAL_BAND_ROWS.x and tile.y <= CENTRAL_BAND_ROWS.y:
			return true
	return false


static func _mirror_tiles(tiles: Array[Vector2i]) -> Array[Vector2i]:
	var mirrored: Array[Vector2i] = []
	for tile: Vector2i in tiles:
		mirrored.append(GameConfig.mirror_tile(tile))
	return mirrored


static func _same_tile_set(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
	if a.size() != b.size():
		return false
	var set_a: Dictionary[Vector2i, bool] = {}
	for tile: Vector2i in a:
		set_a[tile] = true
	for tile: Vector2i in b:
		if not set_a.has(tile):
			return false
	return true


static func _tiles_not_in(source: Array[Vector2i], other: Array[Vector2i]) -> Array[Vector2i]:
	var lookup: Dictionary[Vector2i, bool] = {}
	for tile: Vector2i in other:
		lookup[tile] = true
	var result: Array[Vector2i] = []
	for tile: Vector2i in source:
		if not lookup.has(tile):
			result.append(tile)
	return result


static func _unit_key(unit_type: int, tile: Vector2i) -> String:
	return "%d|%d|%d" % [unit_type, tile.x, tile.y]
