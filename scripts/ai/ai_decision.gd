class_name AiDecision
extends RefCounted

const NO_TILE: Vector2i = Vector2i(-1, -1)

enum Kind {
	PASS = 0,
	BRIDGE = 1,
	RECRUIT = 2,
	MOVE = 3,
	CAPTURE = 4,
	KING_CAPTURE = 5,
}

var action: GameAction
var kind: Kind = Kind.PASS
var score: float = 0.0
var unit_id: int = -1
var from_tile: Vector2i = NO_TILE
var to_tile: Vector2i = NO_TILE
var reason: String = ""


func _init(
	decision_action: GameAction = null,
	decision_kind: Kind = Kind.PASS,
	decision_score: float = 0.0,
	decision_unit_id: int = -1,
	decision_from: Vector2i = NO_TILE,
	decision_to: Vector2i = NO_TILE,
	decision_reason: String = ""
) -> void:
	action = decision_action
	kind = decision_kind
	score = decision_score
	unit_id = decision_unit_id
	from_tile = decision_from
	to_tile = decision_to
	reason = decision_reason


func is_pass() -> bool:
	return kind == Kind.PASS


func signature() -> String:
	var action_text := action.describe() if action != null else "none"
	return "%d|%d|%d,%d|%d,%d|%s" % [
		int(kind),
		unit_id,
		from_tile.x,
		from_tile.y,
		to_tile.x,
		to_tile.y,
		action_text,
	]
