class_name VisionRules
extends RefCounted


static func effective_vision(board: BoardData, unit: GameUnit) -> int:
	var base: int = unit.definition().base_vision
	var tile := board.get_tile(unit.tile)
	if tile == null:
		return maxi(1, base)
	var terrain := TerrainRegistry.get_definition(tile.terrain)
	var modifier := terrain.vision_modifier
	if terrain.is_water:
		modifier = 0
		if unit.type == UnitType.Type.SCOUT and not tile.has_bridge:
			modifier = terrain.vision_modifier
	return maxi(1, base + modifier)
