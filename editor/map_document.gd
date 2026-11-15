class_name MapDocument
extends RefCounted

const DEFAULT_MAP_ID: String = "untitled"
const DEFAULT_MAP_NAME: String = "Untitled Map"
const PLACEABLE_STARTING_TYPES: Array[int] = [
	UnitType.Type.KING,
	UnitType.Type.QUEEN,
	UnitType.Type.ROOK,
	UnitType.Type.BISHOP,
	UnitType.Type.KNIGHT,
	UnitType.Type.PAWN,
]
const BACK_RANK: Array[int] = [
	UnitType.Type.ROOK,
	UnitType.Type.KNIGHT,
	UnitType.Type.BISHOP,
	UnitType.Type.QUEEN,
	UnitType.Type.KING,
	UnitType.Type.BISHOP,
	UnitType.Type.KNIGHT,
	UnitType.Type.ROOK,
]

var map: MapData
var source_path: String = ""
var dirty: bool = false


func _init(map_data: MapData = null) -> void:
	if map_data == null:
		map = _build_new_map(DEFAULT_MAP_ID, DEFAULT_MAP_NAME)
	else:
		map = map_data


static func create_new(
	map_id: String = DEFAULT_MAP_ID,
	map_name: String = DEFAULT_MAP_NAME
) -> MapDocument:
	return MapDocument.new(_build_new_map(map_id, map_name))


static func from_map(source: MapData, path: String = "") -> MapDocument:
	var document := MapDocument.new(source.duplicate_map())
	document.source_path = path
	return document


func set_id(value: String) -> void:
	if map.id == value:
		return
	map.id = value
	dirty = true


func set_name(value: String) -> void:
	if map.name == value:
		return
	map.name = value
	dirty = true


func mark_clean(saved_path: String = "") -> void:
	if not saved_path.is_empty():
		source_path = saved_path
	dirty = false


func get_terrain(tile: Vector2i) -> int:
	var data := map.board.get_tile(tile)
	if data == null:
		return -1
	return data.terrain


func has_mine(tile: Vector2i) -> bool:
	return map.gold_mines.has(tile)


func paint_terrain(tile: Vector2i, terrain: int) -> bool:
	if not TerrainRegistry.get_all_types().has(terrain):
		return false
	var mirror := GameConfig.mirror_tile(tile)
	if not map.board.is_playable(tile) or not map.board.is_playable(mirror):
		return false
	map.board.get_tile(tile).terrain = terrain
	map.board.get_tile(mirror).terrain = terrain
	dirty = true
	return true


func toggle_mine(tile: Vector2i) -> bool:
	var mirror := GameConfig.mirror_tile(tile)
	if has_mine(tile) or has_mine(mirror):
		_remove_mine(tile)
		if mirror != tile:
			_remove_mine(mirror)
		dirty = true
		return true
	if not map.board.is_playable(tile) or not map.board.is_playable(mirror):
		return false
	if _is_water(tile) or _is_water(mirror):
		return false
	map.gold_mines.append(tile)
	if mirror != tile:
		map.gold_mines.append(mirror)
	dirty = true
	return true


func place_starting_unit(player: int, unit_type: int, tile: Vector2i) -> bool:
	if player != GameConfig.Player.PLAYER_1 and player != GameConfig.Player.PLAYER_2:
		return false
	if not PLACEABLE_STARTING_TYPES.has(unit_type):
		return false
	var mirror := GameConfig.mirror_tile(tile)
	var opponent := GameConfig.opponent(player)
	if not _can_host_starting_unit(player, tile):
		return false
	if not _can_host_starting_unit(opponent, mirror):
		return false
	_remove_unit_at(tile)
	_remove_unit_at(mirror)
	var units := map.get_starting_units(player)
	units.append(MapStartingUnit.new(unit_type, tile))
	map.set_starting_units(player, units)
	var opponent_units := map.get_starting_units(opponent)
	opponent_units.append(MapStartingUnit.new(unit_type, mirror))
	map.set_starting_units(opponent, opponent_units)
	dirty = true
	return true


func remove_starting_unit(tile: Vector2i) -> bool:
	var removed := _remove_unit_at(tile)
	var mirror := GameConfig.mirror_tile(tile)
	if mirror != tile:
		removed = _remove_unit_at(mirror) or removed
	if removed:
		dirty = true
	return removed


func get_starting_unit_at(tile: Vector2i) -> MapStartingUnit:
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		for unit: MapStartingUnit in map.get_starting_units(player):
			if unit.tile == tile:
				return unit
	return null


func get_composition(player: int) -> Dictionary[int, int]:
	var counts: Dictionary[int, int] = {}
	for unit: MapStartingUnit in map.get_starting_units(player):
		counts[unit.type] = int(counts.get(unit.type, 0)) + 1
	return counts


func validate() -> Array[MapValidationIssue]:
	return MapValidator.validate_issues(map, true)


func is_exportable() -> bool:
	return validate().is_empty()


func default_save_path() -> String:
	if not source_path.is_empty():
		return source_path
	var file_name := map.id.validate_filename()
	if file_name.is_empty():
		return "user://untitled.json"
	return "user://%s.json" % file_name


func default_export_path() -> String:
	var file_name := map.id.validate_filename()
	if file_name.is_empty():
		return ""
	return "%s/%s.json" % [GameConfig.MAP_LIBRARY_DIRECTORY, file_name]


func load_draft(path: String) -> Array[String]:
	var result := MapIO.load_from_file(path, false)
	if not result.is_valid():
		return result.errors
	map = result.map
	source_path = path
	dirty = false
	return []


func save_draft(path: String) -> Array[String]:
	var errors := _metadata_errors()
	if not errors.is_empty():
		return errors
	if _is_library_path(path):
		errors.append("Use Export to write a validated map into the map library.")
		return errors
	var error := MapIO.save_to_file(map, path)
	if error != OK:
		errors.append("Cannot save map to %s (error %d)." % [path, error])
		return errors
	mark_clean(path)
	return []


func export_map(path: String) -> Array[String]:
	var errors := _metadata_errors()
	if errors.is_empty():
		errors = _validation_messages()
	if errors.is_empty():
		errors = _duplicate_library_id_errors(path)
	if not errors.is_empty():
		return errors
	var error := MapIO.save_to_file(map, path)
	if error != OK:
		errors.append("Cannot export map to %s (error %d)." % [path, error])
		return errors
	mark_clean(path)
	return []


func _metadata_errors() -> Array[String]:
	var errors: Array[String] = []
	if map.id.strip_edges().is_empty():
		errors.append("Map id must not be empty.")
	if map.name.strip_edges().is_empty():
		errors.append("Map name must not be empty.")
	return errors


func _validation_messages() -> Array[String]:
	var errors: Array[String] = []
	for issue: MapValidationIssue in validate():
		errors.append(issue.message)
	return errors


func _duplicate_library_id_errors(path: String) -> Array[String]:
	var errors: Array[String] = []
	for existing_path: String in MapLibrary.paths_for_id(map.id):
		if not _same_path(existing_path, path):
			errors.append("Map id '%s' already exists at %s." % [map.id, existing_path])
	return errors


static func _is_library_path(path: String) -> bool:
	var target := _normalized_absolute(path)
	var library := _normalized_absolute(GameConfig.MAP_LIBRARY_DIRECTORY)
	return target == library or target.begins_with(library + "/")


static func _same_path(a: String, b: String) -> bool:
	return _normalized_absolute(a) == _normalized_absolute(b)


static func _normalized_absolute(path: String) -> String:
	var normalized := ProjectSettings.globalize_path(path).replace("\\", "/").simplify_path()
	if OS.get_name() == "Windows":
		normalized = normalized.to_lower()
	return normalized


func _can_host_starting_unit(player: int, tile: Vector2i) -> bool:
	if not map.board.is_playable(tile):
		return false
	if not GameConfig.is_in_home_half(player, tile.y):
		return false
	return map.board.is_passable(tile)


func _remove_unit_at(tile: Vector2i) -> bool:
	var removed := false
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var kept: Array[MapStartingUnit] = []
		for unit: MapStartingUnit in map.get_starting_units(player):
			if unit.tile == tile:
				removed = true
			else:
				kept.append(unit)
		map.set_starting_units(player, kept)
	return removed


func _remove_mine(tile: Vector2i) -> void:
	var index := map.gold_mines.find(tile)
	if index >= 0:
		map.gold_mines.remove_at(index)


func _is_water(tile: Vector2i) -> bool:
	var data := map.board.get_tile(tile)
	if data == null:
		return true
	return TerrainRegistry.get_definition(data.terrain).is_water


static func _build_new_map(map_id: String, map_name: String) -> MapData:
	var board := BoardData.create_standard()
	var created := MapData.new(board, map_id, map_name)
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		created.set_deployment_tiles(
			player, MapValidator.derived_deployment_tiles(board, player)
		)
		created.set_starting_units(player, _standard_layout(player))
	return created


static func _standard_layout(player: int) -> Array[MapStartingUnit]:
	var units: Array[MapStartingUnit] = []
	for index in BACK_RANK.size():
		var p1_tile := Vector2i(4 + index, 15)
		units.append(
			MapStartingUnit.new(BACK_RANK[index], _layout_tile(player, p1_tile))
		)
	for column in range(4, 12):
		units.append(
			MapStartingUnit.new(
				UnitType.Type.PAWN, _layout_tile(player, Vector2i(column, 14))
			)
		)
	return units


static func _layout_tile(player: int, player_one_tile: Vector2i) -> Vector2i:
	if player == GameConfig.Player.PLAYER_1:
		return player_one_tile
	return GameConfig.mirror_tile(player_one_tile)
