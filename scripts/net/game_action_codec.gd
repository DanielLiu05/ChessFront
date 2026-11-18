class_name GameActionCodec
extends RefCounted

const TYPE_MOVE: String = "move"
const TYPE_RECRUIT: String = "recruit"
const TYPE_BUILD_BRIDGE: String = "build_bridge"
const TYPE_DESTROY_BRIDGE: String = "destroy_bridge"
const TYPE_PASS: String = "pass"


static func encode(action: GameAction) -> Dictionary:
	if action is MoveAction:
		var move := action as MoveAction
		if move.unit_id <= 0 or not _is_tile_in_bounds(move.destination):
			return {}
		if not MovementRules.is_valid_promotion_type(move.promotion_type):
			return {}
		return {
			"type": TYPE_MOVE,
			"unit_id": move.unit_id,
			"destination": _tile_to_array(move.destination),
			"promotion_type": move.promotion_type,
		}
	if action is RecruitAction:
		var recruit := action as RecruitAction
		if not _is_purchasable_type(recruit.unit_type):
			return {}
		if not _is_tile_in_bounds(recruit.spawn_tile):
			return {}
		return {
			"type": TYPE_RECRUIT,
			"unit_type": recruit.unit_type,
			"spawn_tile": _tile_to_array(recruit.spawn_tile),
		}
	if action is BuildBridgeAction:
		var build := action as BuildBridgeAction
		if build.engineer_id <= 0 or not _is_tile_in_bounds(build.target_tile):
			return {}
		return {
			"type": TYPE_BUILD_BRIDGE,
			"engineer_id": build.engineer_id,
			"target_tile": _tile_to_array(build.target_tile),
		}
	if action is DestroyBridgeAction:
		var destroy := action as DestroyBridgeAction
		if destroy.engineer_id <= 0 or not _is_tile_in_bounds(destroy.target_tile):
			return {}
		return {
			"type": TYPE_DESTROY_BRIDGE,
			"engineer_id": destroy.engineer_id,
			"target_tile": _tile_to_array(destroy.target_tile),
		}
	if action is PassAction:
		return {"type": TYPE_PASS}
	return {}


static func decode(data: Dictionary) -> GameAction:
	var type_value: Variant = data.get("type")
	if typeof(type_value) != TYPE_STRING:
		return null
	match String(type_value):
		TYPE_MOVE:
			var unit_id := _integer_field(data, "unit_id")
			var destination := _tile_field(data, "destination")
			var promotion_type := _integer_field(data, "promotion_type")
			if unit_id <= 0 or destination == Vector2i(-1, -1):
				return null
			if not MovementRules.is_valid_promotion_type(promotion_type):
				return null
			return MoveAction.new(unit_id, destination, promotion_type)
		TYPE_RECRUIT:
			var unit_type := _integer_field(data, "unit_type")
			var spawn_tile := _tile_field(data, "spawn_tile")
			if not _is_purchasable_type(unit_type) or spawn_tile == Vector2i(-1, -1):
				return null
			return RecruitAction.new(unit_type, spawn_tile)
		TYPE_BUILD_BRIDGE:
			var build_engineer := _integer_field(data, "engineer_id")
			var build_tile := _tile_field(data, "target_tile")
			if build_engineer <= 0 or build_tile == Vector2i(-1, -1):
				return null
			return BuildBridgeAction.new(build_engineer, build_tile)
		TYPE_DESTROY_BRIDGE:
			var destroy_engineer := _integer_field(data, "engineer_id")
			var destroy_tile := _tile_field(data, "target_tile")
			if destroy_engineer <= 0 or destroy_tile == Vector2i(-1, -1):
				return null
			return DestroyBridgeAction.new(destroy_engineer, destroy_tile)
		TYPE_PASS:
			return PassAction.new()
	return null


static func _integer_field(data: Dictionary, key: String) -> int:
	var value: Variant = data.get(key)
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		if is_finite(number) and number == floorf(number):
			return int(number)
	return -1


static func _tile_field(data: Dictionary, key: String) -> Vector2i:
	var value: Variant = data.get(key)
	if typeof(value) != TYPE_ARRAY:
		return Vector2i(-1, -1)
	var entries: Array = value
	if entries.size() != 2:
		return Vector2i(-1, -1)
	var x := _integer_value(entries[0])
	var y := _integer_value(entries[1])
	if x < 0 or y < 0:
		return Vector2i(-1, -1)
	var tile := Vector2i(x, y)
	if not _is_tile_in_bounds(tile):
		return Vector2i(-1, -1)
	return tile


static func _integer_value(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		if is_finite(number) and number == floorf(number):
			return int(number)
	return -1


static func _tile_to_array(tile: Vector2i) -> Array:
	return [tile.x, tile.y]


static func _is_tile_in_bounds(tile: Vector2i) -> bool:
	return (
		tile.x >= 0
		and tile.x < GameConfig.BOARD_WIDTH
		and tile.y >= 0
		and tile.y < GameConfig.BOARD_HEIGHT
	)


static func _is_purchasable_type(unit_type: int) -> bool:
	if unit_type not in UnitRegistry.get_all_types():
		return false
	return UnitRegistry.is_purchasable(unit_type)
