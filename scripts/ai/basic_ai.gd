class_name BasicAi
extends RefCounted

const NO_TILE: Vector2i = Vector2i(-1, -1)


static func decide(
	observation: AiObservation,
	last_known_enemy_king: Vector2i = NO_TILE,
	last_moved_unit_id: int = -1,
	last_move_origin: Vector2i = NO_TILE
) -> AiDecision:
	if observation == null or observation.view == null:
		return AiDecision.new(
			PassAction.new(), AiDecision.Kind.PASS, 0.0, -1, NO_TILE, NO_TILE, "No observation"
		)
	var view := observation.view
	var king_target := last_known_enemy_king
	if king_target == NO_TILE:
		king_target = _known_enemy_king_tile(view, observation.player)
	var threats := _known_threat_tiles(view)
	var unexplored := _unexplored_tiles(view)
	var candidates: Array[AiDecision] = []

	for unit: GameUnit in view.get_units_for_player(observation.player):
		var destinations := MovementRules.legal_destinations(view, unit, view.exploration)
		for destination: Vector2i in destinations:
			candidates.append(
				_score_move(
					observation,
					unit,
					destination,
					king_target,
					last_moved_unit_id,
					last_move_origin,
					threats,
					unexplored
				)
			)

	var recruit := _recruit_decision(observation, king_target)
	if recruit != null:
		candidates.append(recruit)
	candidates.append_array(_bridge_build_decisions(observation))

	if candidates.is_empty():
		candidates.append_array(_bridge_destroy_decisions(observation))
	if candidates.is_empty():
		return AiDecision.new(
			PassAction.new(), AiDecision.Kind.PASS, 0.0, -1, NO_TILE, NO_TILE, "Pass"
		)
	return _choose_best(candidates)


static func should_accept_draw(_observation: AiObservation) -> bool:
	return false


static func should_offer_draw() -> bool:
	return false


static func _score_move(
	observation: AiObservation,
	unit: GameUnit,
	destination: Vector2i,
	king_target: Vector2i,
	last_moved_unit_id: int,
	last_move_origin: Vector2i,
	threats: Dictionary[Vector2i, bool],
	unexplored: Array[Vector2i]
) -> AiDecision:
	var view := observation.view
	var action := MoveAction.new(unit.id, destination, UnitType.Type.QUEEN)
	var target := view.get_unit_at(destination)
	var kind := AiDecision.Kind.MOVE
	var score := 0.0
	var reason := "Advance"

	if target != null and target.owner != observation.player:
		if target.type == UnitType.Type.KING:
			return AiDecision.new(
				action,
				AiDecision.Kind.KING_CAPTURE,
				AiConfig.KING_VALUE,
				unit.id,
				unit.tile,
				destination,
				"Capture King"
			)
		kind = AiDecision.Kind.CAPTURE
		score += AiConfig.unit_value(target.type) + AiConfig.CAPTURE_BONUS
		reason = "Capture %s" % target.definition().display_name

	var mines := view.known_mines
	if not mines.is_empty():
		var old_mine_distance := _nearest_distance(unit.tile, mines)
		var new_mine_distance := _nearest_distance(destination, mines)
		score += (old_mine_distance - new_mine_distance) * AiConfig.MINE_PROGRESS_PER_TILE
		if destination in mines:
			score += AiConfig.MINE_TILE_BONUS
			if kind == AiDecision.Kind.MOVE:
				reason = "Contest mine"
		elif _is_adjacent_to_any(destination, mines):
			score += AiConfig.MINE_ADJACENT_BONUS
	if destination in view.visible_gold_token_tiles:
		score += AiConfig.GOLD_TOKEN_BONUS
		reason = "Collect gold"

	if king_target != NO_TILE:
		var old_king_distance := _chebyshev(unit.tile, king_target)
		var new_king_distance := _chebyshev(destination, king_target)
		score += (old_king_distance - new_king_distance) * AiConfig.KING_PROGRESS_PER_TILE
		if new_king_distance <= 1:
			score += AiConfig.KING_THREAT_BONUS
			if kind == AiDecision.Kind.MOVE:
				reason = "Threaten King"
		elif kind == AiDecision.Kind.MOVE and old_king_distance > new_king_distance:
			reason = "Pursue King"

	if not unexplored.is_empty():
		var old_frontier := _nearest_distance(unit.tile, unexplored)
		var new_frontier := _nearest_distance(destination, unexplored)
		score += (old_frontier - new_frontier) * AiConfig.FRONTIER_PROGRESS_PER_TILE
		if _adjacent_unexplored_count(destination, view) > 0:
			score += AiConfig.EXPLORE_BONUS
			if kind == AiDecision.Kind.MOVE and reason == "Advance":
				reason = "Explore"

	if MovementRules.requires_promotion(unit, destination):
		score += AiConfig.PROMOTION_BONUS
	if threats.has(destination):
		score -= AiConfig.unit_value(unit.type) * AiConfig.THREAT_PENALTY_SCALE
	if unit.id == last_moved_unit_id and destination == last_move_origin:
		score -= AiConfig.REVERSAL_PENALTY

	return AiDecision.new(
		action, kind, score, unit.id, unit.tile, destination, reason
	)


static func _recruit_decision(
	observation: AiObservation,
	king_target: Vector2i
) -> AiDecision:
	var view := observation.view
	var best_type := -1
	var best_price := -1
	var best_value := -1.0
	for unit_type: int in UnitRegistry.get_all_types():
		var definition := UnitRegistry.get_definition(unit_type)
		if not definition.purchasable or definition.price > observation.gold:
			continue
		var value := AiConfig.unit_value(unit_type)
		if definition.price > best_price \
				or (definition.price == best_price and value > best_value):
			best_type = unit_type
			best_price = definition.price
			best_value = value
	if best_type == -1:
		return null

	var spawns: Array[Vector2i] = []
	for tile: Vector2i in view.deployment_tiles:
		if not view.board.is_playable(tile) or not view.board.is_passable(tile):
			continue
		if view.is_occupied(tile):
			continue
		spawns.append(tile)
	if spawns.is_empty():
		return null
	var spawn := _best_spawn(spawns, view, king_target)
	return AiDecision.new(
		RecruitAction.new(best_type, spawn),
		AiDecision.Kind.RECRUIT,
		AiConfig.RECRUIT_BASE + AiConfig.unit_value(best_type) * 0.1,
		-1,
		NO_TILE,
		spawn,
		"Recruit"
	)


static func _best_spawn(
	spawns: Array[Vector2i],
	view: PlayerView,
	king_target: Vector2i
) -> Vector2i:
	var best := NO_TILE
	var best_distance := AiConfig.NO_DISTANCE
	var center := Vector2i(
		int(GameConfig.BOARD_WIDTH / 2), int(GameConfig.BOARD_HEIGHT / 2)
	)
	for tile: Vector2i in spawns:
		var distance := 0
		if king_target != NO_TILE:
			distance = _chebyshev(tile, king_target)
		elif not view.known_mines.is_empty():
			distance = _nearest_distance(tile, view.known_mines)
		else:
			distance = _chebyshev(tile, center)
		if best == NO_TILE or distance < best_distance \
				or (
					distance == best_distance
					and (tile.y < best.y or (tile.y == best.y and tile.x < best.x))
				):
			best = tile
			best_distance = distance
	return best


static func _bridge_build_decisions(observation: AiObservation) -> Array[AiDecision]:
	var decisions: Array[AiDecision] = []
	for unit: GameUnit in observation.view.get_units_for_player(observation.player):
		if not unit.definition().has_ability(UnitDefinition.Ability.BUILD_BRIDGES):
			continue
		for direction: Vector2i in BoardData.DIRECTIONS:
			var target := unit.tile + direction
			if not BridgeRules.can_build(observation.view, unit, target):
				continue
			var score := AiConfig.BRIDGE_BASE
			if _adjacent_unexplored_count(target, observation.view) > 0:
				score += AiConfig.BRIDGE_EXPLORE_BONUS
			decisions.append(
				AiDecision.new(
					BuildBridgeAction.new(unit.id, target),
					AiDecision.Kind.BRIDGE,
					score,
					unit.id,
					unit.tile,
					target,
					"Build bridge"
				)
			)
	return decisions


static func _bridge_destroy_decisions(
	observation: AiObservation
) -> Array[AiDecision]:
	var decisions: Array[AiDecision] = []
	for unit: GameUnit in observation.view.get_units_for_player(observation.player):
		if not unit.definition().has_ability(UnitDefinition.Ability.BUILD_BRIDGES):
			continue
		for direction: Vector2i in BoardData.DIRECTIONS:
			var target := unit.tile + direction
			if not BridgeRules.can_destroy(observation.view, unit, target):
				continue
			decisions.append(
				AiDecision.new(
					DestroyBridgeAction.new(unit.id, target),
					AiDecision.Kind.BRIDGE,
					AiConfig.EMERGENCY_BRIDGE_SCORE,
					unit.id,
					unit.tile,
					target,
					"Destroy bridge"
				)
			)
	return decisions


static func _known_threat_tiles(view: PlayerView) -> Dictionary[Vector2i, bool]:
	var threats: Dictionary[Vector2i, bool] = {}
	for enemy: GameUnit in view.get_known_units():
		if enemy.owner == view.player or not enemy.definition().can_capture:
			continue
		if enemy.type == UnitType.Type.PAWN:
			var forward := Vector2i(0, GameConfig.forward_row_delta(enemy.owner))
			for side: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0)]:
				var capture_tile := enemy.tile + forward + side
				if view.board.is_playable(capture_tile):
					threats[capture_tile] = true
			continue
		for destination: Vector2i in MovementRules.legal_destinations(
			view, enemy, view.exploration
		):
			threats[destination] = true
	return threats


static func _unexplored_tiles(view: PlayerView) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile: Vector2i in view.board.get_playable_tiles():
		if not view.knowledge.is_explored(tile):
			tiles.append(tile)
	return tiles


static func _known_enemy_king_tile(view: PlayerView, player: int) -> Vector2i:
	for unit: GameUnit in view.get_known_units():
		if unit.owner != player and unit.type == UnitType.Type.KING:
			return unit.tile
	return NO_TILE


static func _nearest_distance(tile: Vector2i, targets: Array[Vector2i]) -> int:
	var best := AiConfig.NO_DISTANCE
	for target: Vector2i in targets:
		best = mini(best, _chebyshev(tile, target))
	return best


static func _is_adjacent_to_any(tile: Vector2i, targets: Array[Vector2i]) -> bool:
	for target: Vector2i in targets:
		if _chebyshev(tile, target) == 1:
			return true
	return false


static func _adjacent_unexplored_count(tile: Vector2i, view: PlayerView) -> int:
	var count := 0
	for direction: Vector2i in BoardData.DIRECTIONS:
		var neighbor := tile + direction
		if view.board.is_playable(neighbor) and not view.knowledge.is_explored(neighbor):
			count += 1
	return count


static func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


static func _choose_best(candidates: Array[AiDecision]) -> AiDecision:
	var best: AiDecision = null
	for candidate: AiDecision in candidates:
		if best == null or _is_better(candidate, best):
			best = candidate
	return best


static func _is_better(a: AiDecision, b: AiDecision) -> bool:
	if not is_equal_approx(a.score, b.score):
		return a.score > b.score
	if int(a.kind) != int(b.kind):
		return int(a.kind) > int(b.kind)
	if a.unit_id != b.unit_id:
		return a.unit_id < b.unit_id
	if a.to_tile.y != b.to_tile.y:
		return a.to_tile.y < b.to_tile.y
	if a.to_tile.x != b.to_tile.x:
		return a.to_tile.x < b.to_tile.x
	return a.signature() < b.signature()
