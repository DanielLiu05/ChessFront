class_name AiBrain
extends RefCounted

const NO_TILE: Vector2i = Vector2i(-1, -1)

var last_known_enemy_king_tile: Vector2i = NO_TILE
var last_moved_unit_id: int = -1
var last_move_origin: Vector2i = NO_TILE


func decide(observation: AiObservation) -> AiDecision:
	_observe(observation)
	return BasicAi.decide(
		observation,
		last_known_enemy_king_tile,
		last_moved_unit_id,
		last_move_origin
	)


func record_committed(decision: AiDecision) -> void:
	if decision == null:
		return
	if decision.kind == AiDecision.Kind.MOVE \
			or decision.kind == AiDecision.Kind.CAPTURE \
			or decision.kind == AiDecision.Kind.KING_CAPTURE:
		last_moved_unit_id = decision.unit_id
		last_move_origin = decision.from_tile


func should_accept_draw(observation: AiObservation) -> bool:
	return BasicAi.should_accept_draw(observation)


func should_offer_draw() -> bool:
	return BasicAi.should_offer_draw()


func reset() -> void:
	last_known_enemy_king_tile = NO_TILE
	last_moved_unit_id = -1
	last_move_origin = NO_TILE


func _observe(observation: AiObservation) -> void:
	if observation == null or observation.view == null:
		return
	for unit: GameUnit in observation.view.get_known_units():
		if unit.owner != observation.player and unit.type == UnitType.Type.KING:
			last_known_enemy_king_tile = unit.tile
			return
