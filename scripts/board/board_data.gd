class_name BoardData
extends RefCounted

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]

var _tiles: Dictionary[Vector2i, BoardTileData] = {}


static func create_standard() -> BoardData:
	return BoardData.new(GameConfig.STANDARD_ROW_WIDTHS)


func _init(row_widths: Array[int]) -> void:
	_build_mask(row_widths)


func playable_count() -> int:
	return _tiles.size()


func is_in_bounds(tile: Vector2i) -> bool:
	return (
		tile.x >= 0
		and tile.x < GameConfig.BOARD_WIDTH
		and tile.y >= 0
		and tile.y < GameConfig.BOARD_HEIGHT
	)


func is_playable(tile: Vector2i) -> bool:
	return _tiles.has(tile)


func is_passable(tile: Vector2i) -> bool:
	var data := _tiles.get(tile) as BoardTileData
	if data == null:
		return false
	var definition := TerrainRegistry.get_definition(data.terrain)
	if definition.is_water:
		return data.has_bridge
	return definition.passable


func get_tile(tile: Vector2i) -> BoardTileData:
	return _tiles.get(tile) as BoardTileData


func get_playable_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for row in GameConfig.BOARD_HEIGHT:
		for column in GameConfig.BOARD_WIDTH:
			var tile := Vector2i(column, row)
			if _tiles.has(tile):
				tiles.append(tile)
	return tiles


func get_neighbors(tile: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for direction: Vector2i in DIRECTIONS:
		var neighbor := tile + direction
		if _tiles.has(neighbor):
			neighbors.append(neighbor)
	return neighbors


func is_point_symmetric_geometry() -> bool:
	for tile: Vector2i in _tiles:
		if not _tiles.has(GameConfig.mirror_tile(tile)):
			return false
	return true


func duplicate_board() -> BoardData:
	var widths: Array[int] = []
	widths.resize(GameConfig.BOARD_HEIGHT)
	widths.fill(0)
	for tile: Vector2i in _tiles:
		widths[tile.y] += 1
	var copy := BoardData.new(widths)
	# Occupancy is not copied; GameState rebuilds it while deploying units.
	for coord: Vector2i in _tiles:
		var source := _tiles[coord]
		var target := copy.get_tile(coord)
		target.terrain = source.terrain
		target.elevation = source.elevation
		target.has_bridge = source.has_bridge
		target.ground_gold = source.ground_gold
	return copy


func _build_mask(row_widths: Array[int]) -> void:
	if row_widths.size() != GameConfig.BOARD_HEIGHT:
		push_error("Board mask must define exactly %d rows" % GameConfig.BOARD_HEIGHT)
		return
	for row in GameConfig.BOARD_HEIGHT:
		var width: int = row_widths[row]
		if width < 0 or width > GameConfig.BOARD_WIDTH or width % 2 != 0:
			push_error("Invalid row width %d at row %d" % [width, row])
			continue
		var start_column: int = int((GameConfig.BOARD_WIDTH - width) / 2.0)
		for column in range(start_column, start_column + width):
			var tile := Vector2i(column, row)
			_tiles[tile] = BoardTileData.new(tile)
