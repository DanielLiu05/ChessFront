class_name MapData
extends RefCounted

const FORMAT_VERSION: int = 1

var format_version: int = FORMAT_VERSION
var id: String = ""
var name: String = ""
var board: BoardData
var gold_mines: Array[Vector2i] = []
var deployment_tiles: Dictionary[int, Array] = {}
var starting_units: Dictionary[int, Array] = {}


func _init(map_board: BoardData, map_id: String = "", map_name: String = "") -> void:
	board = map_board
	id = map_id
	name = map_name
	deployment_tiles[GameConfig.Player.PLAYER_1] = []
	deployment_tiles[GameConfig.Player.PLAYER_2] = []
	starting_units[GameConfig.Player.PLAYER_1] = []
	starting_units[GameConfig.Player.PLAYER_2] = []


func get_deployment_tiles(player: GameConfig.Player) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var raw: Array = deployment_tiles.get(player, [])
	for tile: Vector2i in raw:
		tiles.append(tile)
	return tiles


func set_deployment_tiles(player: GameConfig.Player, tiles: Array[Vector2i]) -> void:
	deployment_tiles[player] = tiles.duplicate()


func get_starting_units(player: GameConfig.Player) -> Array[MapStartingUnit]:
	var units: Array[MapStartingUnit] = []
	var raw: Array = starting_units.get(player, [])
	for unit: MapStartingUnit in raw:
		units.append(unit)
	return units


func set_starting_units(player: GameConfig.Player, units: Array[MapStartingUnit]) -> void:
	starting_units[player] = units.duplicate()


func duplicate_map() -> MapData:
	var copy := MapData.new(board.duplicate_board(), id, name)
	copy.format_version = format_version
	for tile: Vector2i in gold_mines:
		copy.gold_mines.append(tile)
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		copy.set_deployment_tiles(player, get_deployment_tiles(player))
		var copied_units: Array[MapStartingUnit] = []
		for unit: MapStartingUnit in get_starting_units(player):
			copied_units.append(MapStartingUnit.new(unit.type, unit.tile))
		copy.set_starting_units(player, copied_units)
	return copy

