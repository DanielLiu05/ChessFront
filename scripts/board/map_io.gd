class_name MapIO
extends RefCounted


static func load_from_file(path: String, validate: bool = true) -> MapLoadResult:
	var result := MapLoadResult.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.errors.append("Cannot open map file %s (error %d)" % [path, FileAccess.get_open_error()])
		return result
	var text := file.get_as_text()
	file.close()
	return load_from_text(text, validate)


static func load_from_text(text: String, validate: bool = true) -> MapLoadResult:
	var result := MapLoadResult.new()
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		result.errors.append(
			"Invalid JSON at line %d: %s" % [json.get_error_line(), json.get_error_message()]
		)
		return result
	var data: Variant = json.data
	if not (data is Dictionary):
		result.errors.append("Map file must contain a JSON object")
		return result
	_parse_map(data as Dictionary, result, validate)
	return result


static func save_to_file(map: MapData, path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(to_json_text(map))
	file.close()
	return OK


static func to_json_text(map: MapData) -> String:
	return JSON.stringify(_to_data(map), "  ", true) + "\n"


static func _parse_map(data: Dictionary, result: MapLoadResult, validate: bool) -> void:
	var version_value: Variant = _parse_int(data.get("format_version"))
	if version_value == null:
		result.errors.append("format_version must be an integer")
		return
	var version := int(version_value)
	if version != MapData.FORMAT_VERSION:
		result.errors.append(
			"Unsupported map format version %d; expected %d" % [version, MapData.FORMAT_VERSION]
		)
		return

	var map_id: Variant = data.get("id")
	if not (map_id is String) or String(map_id).is_empty():
		result.errors.append("id must be a non-empty string")
		return
	var map_name: Variant = data.get("name")
	if not (map_name is String) or String(map_name).is_empty():
		result.errors.append("name must be a non-empty string")
		return

	var terrain_rows: Variant = data.get("terrain")
	if not (terrain_rows is Array):
		result.errors.append("terrain must be a %dx%d array" % [GameConfig.BOARD_HEIGHT, GameConfig.BOARD_WIDTH])
		return
	var parsed_terrain := _parse_terrain(terrain_rows as Array, result)
	if parsed_terrain.is_empty():
		return
	var widths: Array[int] = []
	widths.assign(parsed_terrain["widths"])
	var terrain_grid: Array = parsed_terrain["terrain"]

	var elevation_rows: Variant = data.get("elevation")
	if not (elevation_rows is Array):
		result.errors.append("elevation must be a %dx%d array" % [GameConfig.BOARD_HEIGHT, GameConfig.BOARD_WIDTH])
		return
	var elevation_grid := _parse_elevation(elevation_rows as Array, terrain_grid, result)
	if elevation_grid.is_empty():
		return

	var board := BoardData.new(widths)
	for row in GameConfig.BOARD_HEIGHT:
		for column in GameConfig.BOARD_WIDTH:
			var tile := board.get_tile(Vector2i(column, row))
			if tile == null:
				continue
			tile.terrain = int(terrain_grid[row][column])
			tile.elevation = int(elevation_grid[row][column])

	var map := MapData.new(board, String(map_id), String(map_name))
	map.format_version = version
	if not _parse_gold_mines(data.get("gold_mines"), map.gold_mines, result):
		return
	var deployment := _parse_deployment(data.get("deployment"), result)
	if deployment.is_empty():
		return
	map.deployment_tiles = deployment
	var starting_units := _parse_starting_units(data.get("starting_units"), result)
	if starting_units.is_empty():
		return
	map.starting_units = starting_units

	if validate:
		var validation_errors := MapValidator.validate(map)
		if not validation_errors.is_empty():
			result.errors.append_array(validation_errors)
			return
	result.map = map


static func _parse_terrain(rows: Array, result: MapLoadResult) -> Dictionary:
	if rows.size() != GameConfig.BOARD_HEIGHT:
		result.errors.append("terrain must contain %d rows" % GameConfig.BOARD_HEIGHT)
		return {}
	var widths: Array[int] = []
	var terrain_grid: Array = []
	for row in GameConfig.BOARD_HEIGHT:
		var raw_row: Variant = rows[row]
		if not (raw_row is Array) or (raw_row as Array).size() != GameConfig.BOARD_WIDTH:
			result.errors.append(
				"terrain row %d must contain %d cells" % [row, GameConfig.BOARD_WIDTH]
			)
			return {}
		var cells: Array = raw_row as Array
		var parsed_row: Array = []
		var playable_columns: Array[int] = []
		for column in GameConfig.BOARD_WIDTH:
			var raw_cell: Variant = cells[column]
			if raw_cell == null:
				parsed_row.append(null)
				continue
			if not (raw_cell is String):
				result.errors.append(
					"terrain at (%d, %d) must be null or a terrain name" % [column, row]
				)
				return {}
			var terrain_value: Variant = _terrain_from_name(String(raw_cell))
			if terrain_value == null:
				result.errors.append(
					"Unknown terrain '%s' at (%d, %d)" % [String(raw_cell), column, row]
				)
				return {}
			parsed_row.append(int(terrain_value))
			playable_columns.append(column)
		if playable_columns.is_empty():
			widths.append(0)
		else:
			var width: int = playable_columns.size()
			var start_column: int = playable_columns[0]
			var end_column: int = playable_columns[playable_columns.size() - 1]
			var expected_start: int = int((GameConfig.BOARD_WIDTH - width) / 2.0)
			if width % 2 != 0 or end_column - start_column + 1 != width or start_column != expected_start:
				result.errors.append("terrain row %d must be a centered contiguous span" % row)
				return {}
			widths.append(width)
		terrain_grid.append(parsed_row)
	return {"widths": widths, "terrain": terrain_grid}


static func _parse_elevation(rows: Array, terrain_grid: Array, result: MapLoadResult) -> Array:
	if rows.size() != GameConfig.BOARD_HEIGHT:
		result.errors.append("elevation must contain %d rows" % GameConfig.BOARD_HEIGHT)
		return []
	var elevation_grid: Array = []
	for row in GameConfig.BOARD_HEIGHT:
		var raw_row: Variant = rows[row]
		if not (raw_row is Array) or (raw_row as Array).size() != GameConfig.BOARD_WIDTH:
			result.errors.append(
				"elevation row %d must contain %d cells" % [row, GameConfig.BOARD_WIDTH]
			)
			return []
		var cells: Array = raw_row as Array
		var parsed_row: Array[int] = []
		for column in GameConfig.BOARD_WIDTH:
			var value: Variant = _parse_int(cells[column])
			if value == null:
				result.errors.append("elevation at (%d, %d) must be an integer" % [column, row])
				return []
			if int(value) < 0:
				result.errors.append("elevation at (%d, %d) must be non-negative" % [column, row])
				return []
			if terrain_grid[row][column] == null and int(value) != 0:
				result.errors.append("void tile (%d, %d) must have elevation 0" % [column, row])
				return []
			parsed_row.append(int(value))
		elevation_grid.append(parsed_row)
	return elevation_grid


static func _parse_gold_mines(value: Variant, target: Array[Vector2i], result: MapLoadResult) -> bool:
	if not (value is Array):
		result.errors.append("gold_mines must be an array")
		return false
	var entries: Array = value as Array
	for index in entries.size():
		var entry: Variant = entries[index]
		if not (entry is Dictionary):
			result.errors.append("gold_mines[%d] must be an object" % index)
			return false
		var tile: Variant = _parse_tile((entry as Dictionary).get("tile"))
		if tile == null:
			result.errors.append("gold_mines[%d].tile must be [x, y]" % index)
			return false
		target.append(tile)
	return true


static func _parse_deployment(value: Variant, result: MapLoadResult) -> Dictionary[int, Array]:
	if not (value is Dictionary):
		result.errors.append("deployment must be an object")
		return {}
	var data: Dictionary = value as Dictionary
	var parsed: Dictionary[int, Array] = {}
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var key := _player_key(player)
		var raw_tiles: Variant = data.get(key)
		if not (raw_tiles is Array):
			result.errors.append("deployment.%s must be an array of tiles" % key)
			return {}
		var tiles: Array[Vector2i] = []
		var entries: Array = raw_tiles as Array
		for index in entries.size():
			var tile: Variant = _parse_tile(entries[index])
			if tile == null:
				result.errors.append("deployment.%s[%d] must be [x, y]" % [key, index])
				return {}
			tiles.append(tile)
		parsed[player] = tiles
	return parsed


static func _parse_starting_units(value: Variant, result: MapLoadResult) -> Dictionary[int, Array]:
	if not (value is Dictionary):
		result.errors.append("starting_units must be an object")
		return {}
	var data: Dictionary = value as Dictionary
	var parsed: Dictionary[int, Array] = {}
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var key := _player_key(player)
		var raw_units: Variant = data.get(key)
		if not (raw_units is Array):
			result.errors.append("starting_units.%s must be an array" % key)
			return {}
		var units: Array[MapStartingUnit] = []
		var entries: Array = raw_units as Array
		for index in entries.size():
			var entry: Variant = entries[index]
			if not (entry is Dictionary):
				result.errors.append("starting_units.%s[%d] must be an object" % [key, index])
				return {}
			var entry_data: Dictionary = entry as Dictionary
			var type_name: Variant = entry_data.get("type")
			if not (type_name is String):
				result.errors.append("starting_units.%s[%d].type must be a string" % [key, index])
				return {}
			var unit_type: Variant = _unit_type_from_name(String(type_name))
			if unit_type == null:
				result.errors.append(
					"Unknown unit type '%s' in starting_units.%s[%d]" % [String(type_name), key, index]
				)
				return {}
			var tile: Variant = _parse_tile(entry_data.get("tile"))
			if tile == null:
				result.errors.append("starting_units.%s[%d].tile must be [x, y]" % [key, index])
				return {}
			units.append(MapStartingUnit.new(unit_type, tile))
		parsed[player] = units
	return parsed


static func _parse_tile(value: Variant) -> Variant:
	if not (value is Array):
		return null
	var values: Array = value as Array
	if values.size() != 2:
		return null
	var x: Variant = _parse_int(values[0])
	var y: Variant = _parse_int(values[1])
	if x == null or y == null:
		return null
	return Vector2i(int(x), int(y))


static func _parse_int(value: Variant) -> Variant:
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT:
		var number: float = value
		if is_equal_approx(number, roundf(number)):
			return int(number)
	return null


static func _to_data(map: MapData) -> Dictionary:
	var data: Dictionary = {}
	data["format_version"] = map.format_version
	data["id"] = map.id
	data["name"] = map.name
	data["terrain"] = _terrain_rows(map.board)
	data["elevation"] = _elevation_rows(map.board)
	var mines: Array = []
	for tile: Vector2i in map.gold_mines:
		mines.append({"tile": [tile.x, tile.y]})
	data["gold_mines"] = mines
	var deployment: Dictionary = {}
	var starting_units: Dictionary = {}
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var key := _player_key(player)
		var tiles: Array = []
		for tile: Vector2i in map.get_deployment_tiles(player):
			tiles.append([tile.x, tile.y])
		deployment[key] = tiles
		var units: Array = []
		for unit: MapStartingUnit in map.get_starting_units(player):
			units.append({"type": _unit_type_to_name(unit.type), "tile": [unit.tile.x, unit.tile.y]})
		starting_units[key] = units
	data["deployment"] = deployment
	data["starting_units"] = starting_units
	return data


static func _terrain_rows(board: BoardData) -> Array:
	var rows: Array = []
	for row in GameConfig.BOARD_HEIGHT:
		var values: Array = []
		for column in GameConfig.BOARD_WIDTH:
			var tile := board.get_tile(Vector2i(column, row))
			values.append(null if tile == null else _terrain_to_name(tile.terrain))
		rows.append(values)
	return rows


static func _elevation_rows(board: BoardData) -> Array:
	var rows: Array = []
	for row in GameConfig.BOARD_HEIGHT:
		var values: Array = []
		for column in GameConfig.BOARD_WIDTH:
			var tile := board.get_tile(Vector2i(column, row))
			values.append(0 if tile == null else tile.elevation)
		rows.append(values)
	return rows


static func _player_key(player: int) -> String:
	return "player_1" if player == GameConfig.Player.PLAYER_1 else "player_2"


static func _terrain_from_name(name: String) -> Variant:
	match name:
		"ground":
			return TerrainType.Type.GROUND
		"forest":
			return TerrainType.Type.FOREST
		"hill":
			return TerrainType.Type.HILL
		"water":
			return TerrainType.Type.WATER
		_:
			return null


static func _terrain_to_name(terrain: int) -> String:
	match terrain:
		TerrainType.Type.GROUND:
			return "ground"
		TerrainType.Type.FOREST:
			return "forest"
		TerrainType.Type.HILL:
			return "hill"
		TerrainType.Type.WATER:
			return "water"
		_:
			return "ground"


static func _unit_type_from_name(name: String) -> Variant:
	match name:
		"king":
			return UnitType.Type.KING
		"queen":
			return UnitType.Type.QUEEN
		"rook":
			return UnitType.Type.ROOK
		"bishop":
			return UnitType.Type.BISHOP
		"knight":
			return UnitType.Type.KNIGHT
		"pawn":
			return UnitType.Type.PAWN
		"scout":
			return UnitType.Type.SCOUT
		"engineer":
			return UnitType.Type.ENGINEER
		_:
			return null


static func _unit_type_to_name(unit_type: int) -> String:
	match unit_type:
		UnitType.Type.KING:
			return "king"
		UnitType.Type.QUEEN:
			return "queen"
		UnitType.Type.ROOK:
			return "rook"
		UnitType.Type.BISHOP:
			return "bishop"
		UnitType.Type.KNIGHT:
			return "knight"
		UnitType.Type.PAWN:
			return "pawn"
		UnitType.Type.SCOUT:
			return "scout"
		UnitType.Type.ENGINEER:
			return "engineer"
		_:
			return "pawn"
