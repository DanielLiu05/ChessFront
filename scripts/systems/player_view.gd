class_name PlayerView
extends MovementState

var player: GameConfig.Player
var knowledge: PlayerKnowledge
var exploration: ExplorationProvider
var known_units: Dictionary[int, GameUnit] = {}
var occupancy: Dictionary[Vector2i, int] = {}
var deployment_tiles: Array[Vector2i] = []
var known_mines: Array[Vector2i] = []
var visible_gold_token_tiles: Array[Vector2i] = []


static func for_player(state: GameState, view_player: GameConfig.Player) -> PlayerView:
	var view := PlayerView.new()
	view.player = view_player
	view.knowledge = state.get_knowledge(view_player)
	view.board = state.board.duplicate_board()
	view._apply_known_terrain(state.board)
	view._apply_known_units(state)
	view.exploration = ExplorationProvider.from_tiles(view.knowledge.explored_tiles())
	view.deployment_tiles = state.get_deployment_tiles(view_player)
	for mine: GoldMine in state.gold_mines:
		if view.knowledge.is_explored(mine.tile):
			view.known_mines.append(mine.tile)
			if mine.gold_available and view.knowledge.is_visible(mine.tile):
				view.visible_gold_token_tiles.append(mine.tile)
	return view


func get_unit_at(tile: Vector2i) -> GameUnit:
	var unit_id: int = occupancy.get(tile, BoardTileData.NO_OCCUPANT)
	if unit_id == BoardTileData.NO_OCCUPANT:
		return null
	return known_units.get(unit_id) as GameUnit


func is_occupied(tile: Vector2i) -> bool:
	return occupancy.has(tile)


func get_known_units() -> Array[GameUnit]:
	var ids := known_units.keys()
	ids.sort()
	var units: Array[GameUnit] = []
	for unit_id: int in ids:
		units.append(known_units[unit_id])
	return units


func get_units_for_player(player: GameConfig.Player) -> Array[GameUnit]:
	var units: Array[GameUnit] = []
	for unit: GameUnit in get_known_units():
		if unit.owner == player:
			units.append(unit)
	return units


func _apply_known_terrain(source: BoardData) -> void:
	for tile: Vector2i in board.get_playable_tiles():
		var target := board.get_tile(tile)
		if knowledge.is_explored(tile):
			var known := knowledge.get_known_tile(tile)
			if not known.is_empty():
				target.terrain = int(known["terrain"])
				target.elevation = int(known["elevation"])
				target.has_bridge = bool(known["has_bridge"])
			else:
				var source_tile := source.get_tile(tile)
				target.terrain = source_tile.terrain
				target.elevation = source_tile.elevation
				target.has_bridge = source_tile.has_bridge
		else:
			target.terrain = TerrainType.Type.GROUND
			target.elevation = 0
			target.has_bridge = false


func _apply_known_units(state: GameState) -> void:
	for unit: GameUnit in state.get_all_units():
		if unit.owner != player and not knowledge.is_enemy_detected(unit.id):
			continue
		known_units[unit.id] = unit
		occupancy[unit.tile] = unit.id
