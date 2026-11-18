class_name MapEditorBoard
extends Control

signal tile_clicked(tile: Vector2i)

const GRID_SIZE: int = 16
const VOID_COLOR: Color = Color(0.10, 0.10, 0.12)
const GROUND_COLOR: Color = Color(0.55, 0.66, 0.44)
const FOREST_COLOR: Color = Color(0.19, 0.42, 0.23)
const HILL_COLOR: Color = Color(0.56, 0.45, 0.27)
const WATER_COLOR: Color = Color(0.18, 0.40, 0.63)
const GRID_LINE_COLOR: Color = Color(0.05, 0.05, 0.05, 0.35)
const DEPLOYMENT_COLOR: Color = Color(0.95, 0.90, 0.45, 0.75)
const MINE_COLOR: Color = Color(1.0, 0.83, 0.20)
const PLAYER_ONE_COLOR: Color = Color(0.24, 0.52, 0.95)
const PLAYER_TWO_COLOR: Color = Color(0.92, 0.30, 0.30)
const UNIT_TEXT_COLOR: Color = Color(1.0, 1.0, 1.0)
const ERROR_COLOR: Color = Color(1.0, 0.15, 0.15)
const HOVER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.9)

var document: MapDocument
var _mine_tiles: Dictionary[Vector2i, bool] = {}
var _deployment_tiles: Dictionary[Vector2i, bool] = {}
var _error_tiles: Dictionary[Vector2i, bool] = {}
var _hover_tile: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	mouse_exited.connect(_on_mouse_exited)


func set_document(value: MapDocument) -> void:
	document = value
	_rebuild_tile_indexes()
	queue_redraw()


func refresh() -> void:
	_rebuild_tile_indexes()
	queue_redraw()


func has_mine_marker(tile: Vector2i) -> bool:
	return _mine_tiles.has(tile)


func set_error_tiles(tiles: Array[Vector2i]) -> void:
	_error_tiles.clear()
	for tile: Vector2i in tiles:
		_error_tiles[tile] = true
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if document == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var cell := _cell_size()
	var origin := _origin(cell)
	var font := ThemeDB.fallback_font
	var font_size := clampi(int(cell * 0.42), 8, 24)
	for row in GRID_SIZE:
		for column in GRID_SIZE:
			var tile := Vector2i(column, row)
			var rect := _tile_rect(tile, cell, origin)
			var data := document.map.board.get_tile(tile)
			if data == null:
				draw_rect(rect, VOID_COLOR, true)
				continue
			draw_rect(rect, _terrain_color(data.terrain), true)
			draw_rect(rect, GRID_LINE_COLOR, false, 1.0)
			if _deployment_tiles.has(tile):
				draw_rect(rect.grow(-2.0), DEPLOYMENT_COLOR, false, 2.0)
			if _mine_tiles.has(tile):
				draw_circle(rect.get_center(), cell * 0.16, MINE_COLOR)
	_draw_units(font, font_size, cell, origin)
	for tile: Vector2i in _error_tiles:
		draw_rect(_tile_rect(tile, cell, origin).grow(-1.0), ERROR_COLOR, false, 3.0)
	if _hover_tile.x >= 0 and document.map.board.is_in_bounds(_hover_tile):
		draw_rect(_tile_rect(_hover_tile, cell, origin).grow(-1.0), HOVER_COLOR, false, 2.0)


func _draw_units(font: Font, font_size: int, cell: float, origin: Vector2) -> void:
	if font == null:
		return
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var color := PLAYER_ONE_COLOR if player == GameConfig.Player.PLAYER_1 else PLAYER_TWO_COLOR
		for unit: MapStartingUnit in document.map.get_starting_units(player):
			var rect := _tile_rect(unit.tile, cell, origin)
			draw_circle(rect.get_center(), cell * 0.32, color)
			draw_string(
				font,
				Vector2(rect.position.x, rect.position.y + (cell + font_size) * 0.5 - 2.0),
				_unit_letter(unit.type),
				HORIZONTAL_ALIGNMENT_CENTER,
				cell,
				font_size,
				UNIT_TEXT_COLOR
			)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var tile := _tile_at(motion.position)
		if tile != _hover_tile:
			_hover_tile = tile
			queue_redraw()
		accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed:
			var tile := _tile_at(mouse.position)
			if tile.x >= 0:
				_hover_tile = tile
				tile_clicked.emit(tile)
				queue_redraw()
			accept_event()


func _on_mouse_exited() -> void:
	_hover_tile = Vector2i(-1, -1)
	queue_redraw()


func _rebuild_tile_indexes() -> void:
	_mine_tiles.clear()
	_deployment_tiles.clear()
	if document == null:
		return
	for tile: Vector2i in document.map.gold_mines:
		_mine_tiles[tile] = true
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		for tile: Vector2i in document.map.get_deployment_tiles(player):
			_deployment_tiles[tile] = true


func _cell_size() -> float:
	return maxf(minf(size.x / float(GRID_SIZE), size.y / float(GRID_SIZE)), 1.0)


func _origin(cell: float) -> Vector2:
	return (size - Vector2(cell * GRID_SIZE, cell * GRID_SIZE)) * 0.5


func _tile_rect(tile: Vector2i, cell: float, origin: Vector2) -> Rect2:
	return Rect2(origin + Vector2(tile) * cell, Vector2(cell, cell))


func _tile_at(position: Vector2) -> Vector2i:
	if document == null or size.x <= 0.0 or size.y <= 0.0:
		return Vector2i(-1, -1)
	var cell := _cell_size()
	var local := position - _origin(cell)
	if local.x < 0.0 or local.y < 0.0:
		return Vector2i(-1, -1)
	var column := int(local.x / cell)
	var row := int(local.y / cell)
	if column < 0 or column >= GRID_SIZE or row < 0 or row >= GRID_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(column, row)


func _terrain_color(terrain: int) -> Color:
	match terrain:
		TerrainType.Type.FOREST:
			return FOREST_COLOR
		TerrainType.Type.HILL:
			return HILL_COLOR
		TerrainType.Type.WATER:
			return WATER_COLOR
		_:
			return GROUND_COLOR


func _unit_letter(unit_type: int) -> String:
	match unit_type:
		UnitType.Type.KING:
			return "K"
		UnitType.Type.QUEEN:
			return "Q"
		UnitType.Type.ROOK:
			return "R"
		UnitType.Type.BISHOP:
			return "B"
		UnitType.Type.KNIGHT:
			return "N"
		UnitType.Type.PAWN:
			return "P"
		UnitType.Type.SCOUT:
			return "S"
		UnitType.Type.ENGINEER:
			return "E"
		_:
			return "?"
