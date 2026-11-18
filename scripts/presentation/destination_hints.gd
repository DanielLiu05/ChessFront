class_name DestinationHints
extends RefCounted


static func path_tiles(view: PlayerView, unit: GameUnit, destination: Vector2i) -> Array[Vector2i]:
	var category := unit.definition().movement_category
	if category == UnitDefinition.MovementCategory.JUMP \
			or category == UnitDefinition.MovementCategory.SINGLE:
		return [destination]
	var delta := destination - unit.tile
	var direction := Vector2i(signi(delta.x), signi(delta.y))
	var distance := maxi(absi(delta.x), absi(delta.y))
	var tiles: Array[Vector2i] = []
	for step in range(1, distance + 1):
		tiles.append(unit.tile + direction * step)
	return tiles


static func frontier_tile(
	view: PlayerView,
	unit: GameUnit,
	destination: Vector2i
) -> Vector2i:
	for tile: Vector2i in path_tiles(view, unit, destination):
		if not view.knowledge.is_explored(tile):
			return tile
	return Vector2i(-1, -1)


static func is_attempt(view: PlayerView, unit: GameUnit, destination: Vector2i) -> bool:
	return frontier_tile(view, unit, destination).x >= 0


static func frontier_tiles(
	view: PlayerView,
	unit: GameUnit,
	destinations: Array[Vector2i]
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for destination: Vector2i in destinations:
		var frontier := frontier_tile(view, unit, destination)
		if frontier.x < 0 or frontier in result:
			continue
		result.append(frontier)
	return result


static func preview_split(
	view: PlayerView,
	unit: GameUnit,
	destination: Vector2i
) -> Dictionary:
	var path := path_tiles(view, unit, destination)
	var frontier := frontier_tile(view, unit, destination)
	var solid: Array[Vector2i] = []
	var uncertain: Array[Vector2i] = []
	for tile: Vector2i in path:
		if frontier.x >= 0 and tile == frontier:
			uncertain.append(tile)
			continue
		if uncertain.is_empty():
			solid.append(tile)
		else:
			uncertain.append(tile)
	return {"solid": solid, "uncertain": uncertain, "frontier": frontier}
