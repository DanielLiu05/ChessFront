class_name GameConfig
extends RefCounted

enum Player {
	PLAYER_1 = 1,
	PLAYER_2 = 2,
}

const BOARD_WIDTH: int = 16
const BOARD_HEIGHT: int = 16
const STANDARD_ROW_WIDTHS: Array[int] = [8, 10, 12, 14, 16, 16, 16, 16, 16, 16, 16, 16, 14, 12, 10, 8]
const FIRST_PLAYER: Player = Player.PLAYER_1
const PLIES_PER_ROUND: int = 2
const DEFAULT_TURN_LIMIT_PLIES: int = 120
const MAP_DIRECTORY: String = "res://maps"
const MAP_LIBRARY_DIRECTORY: String = "res://maps/library"
const NO_PLAYER: int = 0


static func opponent(player: Player) -> Player:
	return Player.PLAYER_2 if player == Player.PLAYER_1 else Player.PLAYER_1


static func forward_row_delta(player: Player) -> int:
	return -1 if player == Player.PLAYER_1 else 1


static func home_row_range(player: Player) -> Vector2i:
	if player == Player.PLAYER_1:
		return Vector2i(8, 15)
	return Vector2i(0, 7)


static func deployment_row_range(player: Player) -> Vector2i:
	if player == Player.PLAYER_1:
		return Vector2i(14, 15)
	return Vector2i(0, 1)


static func promotion_row(player: Player) -> int:
	return 0 if player == Player.PLAYER_1 else 15


static func is_in_home_half(player: Player, row: int) -> bool:
	var rows := home_row_range(player)
	return row >= rows.x and row <= rows.y


static func is_in_deployment_area(player: Player, row: int) -> bool:
	var rows := deployment_row_range(player)
	return row >= rows.x and row <= rows.y


static func mirror_tile(tile: Vector2i) -> Vector2i:
	return Vector2i(BOARD_WIDTH - 1 - tile.x, BOARD_HEIGHT - 1 - tile.y)
