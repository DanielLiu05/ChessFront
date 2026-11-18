class_name MapPreview
extends RefCounted

const CELL_PIXELS: int = 8

static var _cache: Dictionary[String, ImageTexture] = {}


static func texture_for_entry(entry: MapEntry) -> ImageTexture:
	if entry == null:
		return null
	if _cache.has(entry.id):
		return _cache[entry.id]
	var result := MapLibrary.load_map(entry.path)
	if not result.is_valid():
		return null
	var texture := texture_for_map(result.map)
	_cache[entry.id] = texture
	return texture


static func texture_for_map(map: MapData, cell_pixels: int = CELL_PIXELS) -> ImageTexture:
	if map == null or map.board == null:
		return null
	var cell := maxi(cell_pixels, 2)
	var image := Image.create(
		GameConfig.BOARD_WIDTH * cell,
		GameConfig.BOARD_HEIGHT * cell,
		false,
		Image.FORMAT_RGBA8
	)
	image.fill(UiStyle.color("ink"))
	for row in GameConfig.BOARD_HEIGHT:
		for column in GameConfig.BOARD_WIDTH:
			var tile := Vector2i(column, row)
			var data := map.board.get_tile(tile)
			if data == null:
				continue
			_paint_tile(image, tile, data, cell)
	for mine: Vector2i in map.gold_mines:
		_paint_mine(image, mine, cell)
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var accent := (
			UiStyle.color("player_1")
			if player == GameConfig.Player.PLAYER_1
			else UiStyle.color("player_2")
		)
		for tile: Vector2i in map.get_deployment_tiles(player):
			_paint_deployment(image, tile, player, accent, cell)
	_paint_frame(image, UiStyle.color("brass"))
	return ImageTexture.create_from_image(image)


static func clear_cache() -> void:
	_cache.clear()


static func _paint_tile(image: Image, tile: Vector2i, data: BoardTileData, cell: int) -> void:
	var base := _terrain_color(data.terrain).lightened(0.05)
	if data.elevation > 0:
		base = base.lightened(0.08)
	var origin := Vector2i(tile.x * cell, tile.y * cell)
	_fill_rect(image, origin, Vector2i(cell, cell), base)
	match data.terrain:
		TerrainType.Type.FOREST:
			var canopy := base.darkened(0.22)
			_fill_rect(
				image,
				origin + Vector2i(cell / 2 - 1, cell / 2 - 1),
				Vector2i(2, 2),
				canopy
			)
		TerrainType.Type.HILL:
			_fill_rect(
				image,
				origin + Vector2i(2, 2),
				Vector2i(maxi(1, cell - 4), 1),
				base.lightened(0.18)
			)
		TerrainType.Type.WATER:
			_fill_rect(
				image,
				origin + Vector2i(1, cell / 2),
				Vector2i(maxi(1, cell - 2), 1),
				base.lightened(0.22)
			)
	var grid := base.darkened(0.22)
	_fill_rect(image, origin + Vector2i(0, cell - 1), Vector2i(cell, 1), Color(grid, 0.35))
	_fill_rect(image, origin + Vector2i(cell - 1, 0), Vector2i(1, cell), Color(grid, 0.35))


static func _paint_frame(image: Image, frame: Color) -> void:
	var width := image.get_width()
	var height := image.get_height()
	_fill_rect(image, Vector2i.ZERO, Vector2i(width, 1), frame.darkened(0.25))
	_fill_rect(image, Vector2i(0, height - 1), Vector2i(width, 1), frame.darkened(0.25))
	_fill_rect(image, Vector2i.ZERO, Vector2i(1, height), frame.darkened(0.25))
	_fill_rect(image, Vector2i(width - 1, 0), Vector2i(1, height), frame.darkened(0.25))


static func _paint_mine(image: Image, tile: Vector2i, cell: int) -> void:
	var origin := Vector2i(tile.x * cell, tile.y * cell)
	var gold := UiStyle.gold()
	var center := origin + Vector2i(cell / 2, cell / 2)
	_fill_rect(image, center, Vector2i(2, 2), gold)
	if cell >= 6:
		image.set_pixel(center.x - 1, center.y, gold)
		image.set_pixel(center.x + 2, center.y, gold)
		image.set_pixel(center.x, center.y - 1, gold)
		image.set_pixel(center.x, center.y + 2, gold)


static func _paint_deployment(
	image: Image,
	tile: Vector2i,
	player: int,
	accent: Color,
	cell: int
) -> void:
	var origin := Vector2i(tile.x * cell, tile.y * cell)
	var y := origin.y + (cell - 1 if player == GameConfig.Player.PLAYER_1 else 0)
	_fill_rect(image, Vector2i(origin.x, y), Vector2i(cell, 1), Color(accent, 0.92))


static func _fill_rect(image: Image, origin: Vector2i, size: Vector2i, color: Color) -> void:
	var clipped := Rect2i(origin, size).intersection(
		Rect2i(0, 0, image.get_width(), image.get_height())
	)
	if clipped.size.x <= 0 or clipped.size.y <= 0:
		return
	image.fill_rect(clipped, color)


static func _terrain_color(terrain: int) -> Color:
	match terrain:
		TerrainType.Type.FOREST:
			return UiStyle.color("forest")
		TerrainType.Type.HILL:
			return UiStyle.color("hill")
		TerrainType.Type.WATER:
			return UiStyle.color("water").lightened(0.06)
		_:
			return UiStyle.color("ground")
