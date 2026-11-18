class_name VisionSystem
extends RefCounted


static func recompute(
	board: BoardData,
	units: Array[GameUnit],
	knowledge_by_player: Dictionary[int, PlayerKnowledge]
) -> void:
	for player: int in [GameConfig.Player.PLAYER_1, GameConfig.Player.PLAYER_2]:
		var knowledge := knowledge_by_player.get(player) as PlayerKnowledge
		if knowledge != null:
			_recompute_player(board, units, player, knowledge)


static func _recompute_player(
	board: BoardData,
	units: Array[GameUnit],
	player: GameConfig.Player,
	knowledge: PlayerKnowledge
) -> void:
	knowledge.begin_refresh()
	var friendly: Array[GameUnit] = []
	for unit: GameUnit in units:
		if unit.owner == player:
			friendly.append(unit)

	for unit: GameUnit in friendly:
		var radius := VisionRules.effective_vision(board, unit)
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var tile := unit.tile + Vector2i(dx, dy)
				var data := board.get_tile(tile)
				if data != null:
					knowledge.mark_visible(tile)
					knowledge.remember_tile(tile, data.terrain, data.elevation, data.has_bridge)

	for enemy: GameUnit in units:
		if enemy.owner == player:
			continue
		var data := board.get_tile(enemy.tile)
		if data == null:
			continue
		if data.terrain == TerrainType.Type.FOREST:
			if not _has_detector(friendly, enemy.tile):
				continue
		elif not knowledge.is_visible(enemy.tile):
			continue
		knowledge.mark_enemy_detected(enemy.id)


static func _has_detector(observers: Array[GameUnit], enemy_tile: Vector2i) -> bool:
	for observer: GameUnit in observers:
		var distance := 2 if observer.type == UnitType.Type.SCOUT else 1
		var dx := absi(observer.tile.x - enemy_tile.x)
		var dy := absi(observer.tile.y - enemy_tile.y)
		if maxi(dx, dy) <= distance:
			return true
	return false
