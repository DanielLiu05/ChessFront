class_name NetworkViewCodec
extends RefCounted


static func encode(state: GameState, view: PlayerView, local_player: int) -> Dictionary:
	if state == null or view == null or view.player != local_player:
		return {}
	var unit_entries: Array = []
	for unit: GameUnit in view.get_known_units():
		unit_entries.append({
			"id": unit.id,
			"type": int(unit.type),
			"owner": int(unit.owner),
			"tile": _tile_to_array(unit.tile),
		})
	var bridge_entries: Array = []
	for tile: Vector2i in view.board.get_playable_tiles():
		if view.board.get_tile(tile).has_bridge:
			bridge_entries.append(_tile_to_array(tile))
	return {
		"map_id": state.map_id,
		"map_format_version": state.map_format_version,
		"local_player": local_player,
		"ply": state.ply,
		"active_player": int(state.active_player),
		"turn_limit_plies": state.turn_limit_plies,
		"game_over": state.game_over,
		"winner": state.winner,
		"draw_reason": state.draw_reason,
		"draw_offered_by": state.draw_offered_by,
		"own_gold": state.get_gold(local_player),
		"units": unit_entries,
		"bridges": bridge_entries,
		"explored": _tiles_to_arrays(view.knowledge.explored_tiles()),
		"visible": _tiles_to_arrays(view.knowledge.visible_tiles()),
		"known_mines": _tiles_to_arrays(_sorted_tiles(view.known_mines)),
		"visible_gold_tokens": _tiles_to_arrays(
			_sorted_tiles(view.visible_gold_token_tiles)
		),
		"deployment_tiles": _tiles_to_arrays(_sorted_tiles(view.deployment_tiles)),
	}


static func validate(data: Dictionary, map: MapData = null) -> Array[String]:
	var errors: Array[String] = []
	if typeof(data) != TYPE_DICTIONARY:
		errors.append("View is not an object")
		return errors
	var map_id_value: Variant = data.get("map_id")
	if typeof(map_id_value) != TYPE_STRING or String(map_id_value).is_empty():
		errors.append("View has no map id")
	elif map != null and String(map_id_value) != map.id:
		errors.append("View map id does not match the loaded map")
	var format_value: Variant = data.get("map_format_version")
	if not _is_integer(format_value):
		errors.append("View has no integer map format version")
	elif map != null and int(format_value) != map.format_version:
		errors.append("View map format version does not match the loaded map")
	var local_player := _valid_player(data.get("local_player"))
	if local_player == GameConfig.NO_PLAYER:
		errors.append("View local player is invalid")
	var active_player := _valid_player(data.get("active_player"))
	if active_player == GameConfig.NO_PLAYER:
		errors.append("View active player is invalid")
	var ply := _integer_or_minus_one(data.get("ply"))
	if ply < 0:
		errors.append("View ply is invalid")
	var turn_limit := _integer_or_minus_one(data.get("turn_limit_plies"))
	if turn_limit <= 0:
		errors.append("View turn limit is invalid")
	if typeof(data.get("game_over")) != TYPE_BOOL:
		errors.append("View game-over flag is invalid")
	var winner_value: Variant = data.get("winner")
	if not _is_integer(winner_value):
		errors.append("View winner is invalid")
	else:
		var winner := int(winner_value)
		if winner != GameConfig.NO_PLAYER and winner != GameConfig.Player.PLAYER_1 \
				and winner != GameConfig.Player.PLAYER_2:
			errors.append("View winner is not a valid player")
	if typeof(data.get("draw_reason")) != TYPE_STRING:
		errors.append("View draw reason is invalid")
	var draw_offer_value: Variant = data.get("draw_offered_by")
	if not _is_integer(draw_offer_value):
		errors.append("View draw offer is invalid")
	else:
		var draw_offer := int(draw_offer_value)
		if draw_offer != GameConfig.NO_PLAYER and draw_offer != GameConfig.Player.PLAYER_1 \
				and draw_offer != GameConfig.Player.PLAYER_2:
			errors.append("View draw offer is not a valid player")
	var own_gold := _integer_or_minus_one(data.get("own_gold"))
	if own_gold < 0:
		errors.append("View own gold is invalid")

	var explored := _validate_tiles(data.get("explored"), "explored", errors, map)
	var visible := _validate_tiles(data.get("visible"), "visible", errors, map)
	for tile: Vector2i in visible:
		if tile not in explored:
			errors.append("View visible tile %s is not explored" % str(tile))
			break
	var bridges := _validate_tiles(data.get("bridges"), "bridges", errors, map)
	for tile: Vector2i in bridges:
		if tile not in explored:
			errors.append("View bridge tile %s is not explored" % str(tile))
			break
	var known_mines := _validate_tiles(data.get("known_mines"), "known_mines", errors, map)
	var visible_tokens := _validate_tiles(
		data.get("visible_gold_tokens"), "visible_gold_tokens", errors, map
	)
	for tile: Vector2i in visible_tokens:
		if tile not in known_mines:
			errors.append("View visible token tile %s is not a known mine" % str(tile))
			break
	_validate_tiles(data.get("deployment_tiles"), "deployment_tiles", errors, map)
	_validate_units(data.get("units"), errors, map)
	return errors


static func decode(data: Dictionary, map: MapData) -> PlayerView:
	if map == null or not validate(data, map).is_empty():
		return null
	var local_player := int(data["local_player"])
	var knowledge := PlayerKnowledge.new(local_player)
	for tile: Vector2i in _tiles_from_data(data["explored"]):
		knowledge.explored[tile] = true
	for tile: Vector2i in _tiles_from_data(data["visible"]):
		knowledge.visible[tile] = true
		knowledge.explored[tile] = true
	var board := map.board.duplicate_board()
	for tile: Vector2i in board.get_playable_tiles():
		var target := board.get_tile(tile)
		if knowledge.is_explored(tile):
			var source := map.board.get_tile(tile)
			target.terrain = source.terrain
			target.elevation = source.elevation
			target.has_bridge = false
		else:
			target.terrain = TerrainType.Type.GROUND
			target.elevation = 0
			target.has_bridge = false
	for tile: Vector2i in _tiles_from_data(data["bridges"]):
		board.get_tile(tile).has_bridge = true
	var view := PlayerView.new()
	view.player = local_player
	view.knowledge = knowledge
	view.board = board
	view.exploration = ExplorationProvider.from_tiles(knowledge.explored_tiles())
	view.deployment_tiles = _tiles_from_data(data["deployment_tiles"])
	view.known_mines = _tiles_from_data(data["known_mines"])
	view.visible_gold_token_tiles = _tiles_from_data(data["visible_gold_tokens"])
	for entry: Dictionary in data["units"]:
		var unit := GameUnit.new(
			int(entry["id"]),
			int(entry["type"]),
			int(entry["owner"]),
			_tile_from_array(entry["tile"])
		)
		view.known_units[unit.id] = unit
		view.occupancy[unit.tile] = unit.id
		if unit.owner != local_player:
			knowledge.detected_enemy_ids[unit.id] = true
	return view


static func _validate_tiles(
	value: Variant,
	field_name: String,
	errors: Array[String],
	map: MapData
) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if typeof(value) != TYPE_ARRAY:
		errors.append("View %s is not an array" % field_name)
		return tiles
	var seen: Dictionary[Vector2i, bool] = {}
	for raw: Variant in value:
		var tile := _tile_from_array_or_invalid(raw)
		if tile == Vector2i(-1, -1):
			errors.append("View %s contains an invalid tile" % field_name)
			continue
		if map != null and not map.board.is_playable(tile):
			errors.append("View %s contains an unplayable tile %s" % [field_name, str(tile)])
			continue
		if seen.has(tile):
			errors.append("View %s contains duplicate tile %s" % [field_name, str(tile)])
			continue
		seen[tile] = true
		tiles.append(tile)
	return tiles


static func _validate_units(value: Variant, errors: Array[String], map: MapData) -> void:
	if typeof(value) != TYPE_ARRAY:
		errors.append("View units is not an array")
		return
	var ids: Dictionary[int, bool] = {}
	var tiles: Dictionary[Vector2i, bool] = {}
	for raw: Variant in value:
		if typeof(raw) != TYPE_DICTIONARY:
			errors.append("View contains a non-object unit")
			continue
		var entry: Dictionary = raw
		var id := _integer_or_minus_one(entry.get("id"))
		if id <= 0:
			errors.append("View unit id is invalid")
			continue
		if ids.has(id):
			errors.append("View contains duplicate unit id %d" % id)
			continue
		ids[id] = true
		var type := _integer_or_minus_one(entry.get("type"))
		if type not in UnitRegistry.get_all_types():
			errors.append("View unit %d has an invalid type" % id)
			continue
		var owner := _valid_player(entry.get("owner"))
		if owner == GameConfig.NO_PLAYER:
			errors.append("View unit %d has an invalid owner" % id)
			continue
		var tile := _tile_from_array_or_invalid(entry.get("tile"))
		if tile == Vector2i(-1, -1):
			errors.append("View unit %d has an invalid tile" % id)
			continue
		if map != null and not map.board.is_playable(tile):
			errors.append("View unit %d is on an unplayable tile" % id)
			continue
		if tiles.has(tile):
			errors.append("View units overlap at %s" % str(tile))
			continue
		tiles[tile] = true


static func _valid_player(value: Variant) -> int:
	if not _is_integer(value):
		return GameConfig.NO_PLAYER
	var player := int(value)
	if player == GameConfig.Player.PLAYER_1 or player == GameConfig.Player.PLAYER_2:
		return player
	return GameConfig.NO_PLAYER


static func _is_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		return is_finite(number) and number == floorf(number)
	return false


static func _integer_or_minus_one(value: Variant) -> int:
	if not _is_integer(value):
		return -1
	return int(value)


static func _tiles_from_data(value: Array) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for raw: Variant in value:
		var tile := _tile_from_array_or_invalid(raw)
		if tile != Vector2i(-1, -1):
			tiles.append(tile)
	return tiles


static func _tile_from_array_or_invalid(value: Variant) -> Vector2i:
	if typeof(value) != TYPE_ARRAY:
		return Vector2i(-1, -1)
	var entries: Array = value
	if entries.size() != 2:
		return Vector2i(-1, -1)
	var x := _integer_or_minus_one(entries[0])
	var y := _integer_or_minus_one(entries[1])
	if x < 0 or y < 0:
		return Vector2i(-1, -1)
	var tile := Vector2i(x, y)
	if tile.x >= GameConfig.BOARD_WIDTH or tile.y >= GameConfig.BOARD_HEIGHT:
		return Vector2i(-1, -1)
	return tile


static func _tile_from_array(value: Array) -> Vector2i:
	return _tile_from_array_or_invalid(value)


static func _tiles_to_arrays(tiles: Array[Vector2i]) -> Array:
	var entries: Array = []
	for tile: Vector2i in tiles:
		entries.append(_tile_to_array(tile))
	return entries


static func _tile_to_array(tile: Vector2i) -> Array:
	return [tile.x, tile.y]


static func _sorted_tiles(tiles: Array[Vector2i]) -> Array[Vector2i]:
	var sorted := tiles.duplicate()
	sorted.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			if a.y != b.y:
				return a.y < b.y
			return a.x < b.x
	)
	return sorted
