class_name AsciiBoardRenderer
extends RefCounted

const COLUMN_LABELS: String = "0123456789ABCDEF"


static func render(state: GameState) -> String:
	var lines: Array[String] = []
	lines.append("    " + COLUMN_LABELS)
	for row in GameConfig.BOARD_HEIGHT:
		var line := "%2d  " % row
		for column in GameConfig.BOARD_WIDTH:
			line += _tile_symbol(state, Vector2i(column, row))
		lines.append(line)
	return "\n".join(PackedStringArray(lines))


static func render_view(view: PlayerView) -> String:
	var lines: Array[String] = []
	lines.append("    " + COLUMN_LABELS)
	for row in GameConfig.BOARD_HEIGHT:
		var line := "%2d  " % row
		for column in GameConfig.BOARD_WIDTH:
			line += _view_tile_symbol(view, Vector2i(column, row))
		lines.append(line)
	return "\n".join(PackedStringArray(lines))


static func _tile_symbol(state: GameState, tile: Vector2i) -> String:
	var unit := state.get_unit_at(tile)
	if unit != null:
		return _unit_symbol(unit)
	var data := state.board.get_tile(tile)
	if data == null:
		return " "
	if state.is_gold_mine(tile):
		return "G"
	if data.has_bridge:
		return "="
	return _terrain_symbol(data)


static func _view_tile_symbol(view: PlayerView, tile: Vector2i) -> String:
	var unit := view.get_unit_at(tile)
	if unit != null:
		return _unit_symbol(unit)
	var data := view.board.get_tile(tile)
	if data == null:
		return " "
	if not view.knowledge.is_explored(tile):
		return "?"
	if data.has_bridge:
		return "="
	return _terrain_symbol(data)


static func _terrain_symbol(data: BoardTileData) -> String:
	match data.terrain:
		TerrainType.Type.FOREST:
			return "f"
		TerrainType.Type.HILL:
			return "^"
		TerrainType.Type.WATER:
			return "~"
		_:
			return "."


static func _unit_symbol(unit: GameUnit) -> String:
	var symbol := ""
	match unit.type:
		UnitType.Type.KING:
			symbol = "K"
		UnitType.Type.QUEEN:
			symbol = "Q"
		UnitType.Type.ROOK:
			symbol = "R"
		UnitType.Type.BISHOP:
			symbol = "B"
		UnitType.Type.KNIGHT:
			symbol = "N"
		UnitType.Type.PAWN:
			symbol = "P"
		UnitType.Type.SCOUT:
			symbol = "S"
		UnitType.Type.ENGINEER:
			symbol = "E"
	return symbol if unit.owner == GameConfig.Player.PLAYER_1 else symbol.to_lower()
