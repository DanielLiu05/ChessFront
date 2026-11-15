class_name UnitDefinition
extends RefCounted

enum MovementCategory {
	SINGLE,
	RAY,
	STEP,
	JUMP,
}

enum Ability {
	NONE = 0,
	BUILD_BRIDGES = 1 << 0,
}

const UNLIMITED_REACH: int = -1

var type: UnitType.Type
var display_name: String
var base_vision: int
var price: int
var purchasable: bool
var can_capture: bool
var movement_category: MovementCategory
# Tiles. RAY uses UNLIMITED_REACH; JUMP uses 0 because its shape is fixed.
var base_reach: int
var explored_reach: int
var abilities: int


func _init(
	unit_type: UnitType.Type,
	unit_name: String,
	vision: int,
	unit_price: int,
	can_be_purchased: bool,
	captures: bool,
	category: MovementCategory,
	reach: int,
	explored: int,
	ability_flags: int = Ability.NONE
) -> void:
	type = unit_type
	display_name = unit_name
	base_vision = vision
	price = unit_price
	purchasable = can_be_purchased
	can_capture = captures
	movement_category = category
	base_reach = reach
	explored_reach = explored
	abilities = ability_flags


func has_ability(ability: int) -> bool:
	return (abilities & ability) != 0
