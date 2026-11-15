class_name PresentationModel
extends RefCounted

enum ClickResult {
	IGNORED,
	SELECTED,
	DESELECTED,
	ACTION_OK,
	PROMOTION_REQUIRED,
	REJECTED,
}

enum BridgeMode {
	NONE,
	BUILD,
	DESTROY,
}

const NO_TILE: Vector2i = Vector2i(-1, -1)
const MAX_LOG_ENTRIES: int = 200

var state: GameState
var local_player: int
var ai_player: int = GameConfig.NO_PLAYER
var view: PlayerView

var selected_tile: Vector2i = NO_TILE
var selected_unit_id: int = -1
var legal_destinations: Array[Vector2i] = []
var capture_destinations: Array[Vector2i] = []
var bridge_build_targets: Array[Vector2i] = []
var bridge_destroy_targets: Array[Vector2i] = []
var recruitment_spawn_tiles: Array[Vector2i] = []
var pending_promotion_tile: Vector2i = NO_TILE
var pending_promotion_unit_id: int = -1

var last_result: ActionResult
var action_log: Array[String] = []

var _recruitment_type: int = -1
var _bridge_mode: BridgeMode = BridgeMode.NONE


func _init(game_state: GameState, viewer: int) -> void:
	state = game_state
	local_player = viewer
	refresh()


func refresh() -> void:
	view = PlayerView.for_player(state, local_player)
	if not can_interact():
		_clear_selection_state()
		return
	if pending_promotion_unit_id != -1:
		var pending_unit := _known_unit(pending_promotion_unit_id)
		if pending_unit == null or pending_unit.owner != local_player:
			cancel_promotion()
	if selected_unit_id != -1:
		var unit := _known_unit(selected_unit_id)
		if unit == null or unit.owner != local_player:
			_clear_selection_state()
		else:
			selected_tile = unit.tile
			_recompute_selection_highlights(unit)
	else:
		_clear_move_highlights()
	if _recruitment_type != -1:
		recruitment_spawn_tiles = _known_spawn_tiles()
		if recruitment_spawn_tiles.is_empty():
			_recruitment_type = -1
	if _bridge_mode != BridgeMode.NONE:
		var engineer := selected_unit()
		if engineer == null or not _has_bridge_targets_for_mode(engineer):
			_bridge_mode = BridgeMode.NONE


func can_interact() -> bool:
	return not state.game_over and state.active_player == local_player


func side_label(player: int) -> String:
	if player == local_player:
		return "You"
	if ai_player != GameConfig.NO_PLAYER and player == ai_player:
		return "AI"
	return "Player %d" % player


func short_side_label(player: int) -> String:
	if player == local_player:
		return "You"
	if ai_player != GameConfig.NO_PLAYER and player == ai_player:
		return "AI"
	return "P%d" % player


func winner_text() -> String:
	if state == null or not state.game_over:
		return ""
	if state.winner == GameConfig.NO_PLAYER:
		return "Draw"
	if ai_player == GameConfig.NO_PLAYER:
		return "Player %d wins" % state.winner
	if state.winner == local_player:
		return "You win"
	if state.winner == ai_player:
		return "AI wins"
	return "Player %d wins" % state.winner


func gold_summary() -> String:
	if ai_player != GameConfig.NO_PLAYER:
		return "Gold You %d · AI %d" % [gold(local_player), gold(ai_player)]
	return "Gold P1 %d · P2 %d" % [
		gold(GameConfig.Player.PLAYER_1), gold(GameConfig.Player.PLAYER_2)
	]


func has_pending_promotion() -> bool:
	return pending_promotion_unit_id != -1


func selected_unit() -> GameUnit:
	if selected_unit_id == -1:
		return null
	var unit := _known_unit(selected_unit_id)
	if unit == null or unit.owner != local_player:
		return null
	return unit


func select_unit_at(tile: Vector2i) -> bool:
	if not can_interact() or has_pending_promotion():
		return false
	var unit := view.get_unit_at(tile)
	if unit == null or unit.owner != local_player:
		return false
	selected_tile = tile
	selected_unit_id = unit.id
	_recruitment_type = -1
	recruitment_spawn_tiles.clear()
	_bridge_mode = BridgeMode.NONE
	_recompute_selection_highlights(unit)
	return true


func clear_selection() -> void:
	_clear_selection_state()


func click_tile(tile: Vector2i) -> ClickResult:
	if not can_interact() or has_pending_promotion():
		return ClickResult.IGNORED
	if _recruitment_type != -1:
		if tile not in recruitment_spawn_tiles:
			return ClickResult.IGNORED
		var recruit_result := recruit_at(tile)
		return ClickResult.ACTION_OK if recruit_result.success else ClickResult.REJECTED
	if _bridge_mode != BridgeMode.NONE:
		var targets := bridge_build_targets if _bridge_mode == BridgeMode.BUILD else bridge_destroy_targets
		if tile not in targets:
			return ClickResult.IGNORED
		var bridge_result := bridge_action_at(tile)
		return ClickResult.ACTION_OK if bridge_result.success else ClickResult.REJECTED
	var unit := selected_unit()
	if unit != null and tile in legal_destinations:
		if MovementRules.requires_promotion(unit, tile):
			pending_promotion_unit_id = unit.id
			pending_promotion_tile = tile
			return ClickResult.PROMOTION_REQUIRED
		var move_result := move_selected_to(tile, UnitType.Type.QUEEN)
		return ClickResult.ACTION_OK if move_result.success else ClickResult.REJECTED
	var clicked := view.get_unit_at(tile)
	if clicked != null and clicked.owner == local_player:
		select_unit_at(tile)
		return ClickResult.SELECTED
	_clear_selection_state()
	return ClickResult.DESELECTED


func move_selected_to(
	destination: Vector2i,
	promotion_type: int = UnitType.Type.QUEEN
) -> ActionResult:
	var unit := selected_unit()
	if not can_interact():
		return _failure("Not the local player's turn")
	if unit == null:
		return _failure("No unit selected")
	if destination not in legal_destinations:
		return _failure("Destination is not highlighted")
	var action := MoveAction.new(unit.id, destination, promotion_type)
	var result := ActionResolver.resolve(state, action, view.exploration)
	last_result = result
	if result.success:
		_complete_action(action, result)
	return result


func complete_promotion(promotion_type: int) -> ActionResult:
	if not has_pending_promotion():
		return _failure("No promotion is pending")
	if not MovementRules.is_valid_promotion_type(promotion_type):
		return _failure("Invalid promotion choice")
	var unit_id := pending_promotion_unit_id
	var destination := pending_promotion_tile
	var action := MoveAction.new(unit_id, destination, promotion_type)
	var result := ActionResolver.resolve(state, action, view.exploration)
	last_result = result
	if result.success:
		_complete_action(action, result)
	return result


func cancel_promotion() -> void:
	pending_promotion_unit_id = -1
	pending_promotion_tile = NO_TILE


func available_recruitment_units() -> Array[int]:
	var types: Array[int] = []
	if not can_interact():
		return types
	var spawns := _known_spawn_tiles()
	if spawns.is_empty():
		return types
	var gold := state.get_gold(local_player)
	for unit_type: int in UnitRegistry.get_all_types():
		var definition := UnitRegistry.get_definition(unit_type)
		if definition.purchasable and definition.price <= gold:
			types.append(unit_type)
	return types


func has_recruitment_space() -> bool:
	return can_interact() and not _known_spawn_tiles().is_empty()


func can_recruit_unit(unit_type: int) -> bool:
	if not can_interact() or has_pending_promotion():
		return false
	if not (unit_type in UnitRegistry.get_all_types()):
		return false
	var definition := UnitRegistry.get_definition(unit_type)
	if not definition.purchasable:
		return false
	if state.get_gold(local_player) < definition.price:
		return false
	return not _known_spawn_tiles().is_empty()


func begin_recruitment(unit_type: int) -> bool:
	if not can_recruit_unit(unit_type):
		return false
	_recruitment_type = unit_type
	_bridge_mode = BridgeMode.NONE
	selected_tile = NO_TILE
	selected_unit_id = -1
	_clear_move_highlights()
	bridge_build_targets.clear()
	bridge_destroy_targets.clear()
	cancel_promotion()
	recruitment_spawn_tiles = _known_spawn_tiles()
	return not recruitment_spawn_tiles.is_empty()


func recruit_at(tile: Vector2i) -> ActionResult:
	if not can_interact() or has_pending_promotion():
		return _failure("Not the local player's turn")
	if _recruitment_type == -1:
		return _failure("No recruitment is active")
	if tile not in recruitment_spawn_tiles:
		return _failure("Spawn tile is not highlighted")
	var action := RecruitAction.new(_recruitment_type, tile)
	var result := ActionResolver.resolve(state, action, view.exploration)
	last_result = result
	if result.success:
		_complete_action(action, result)
	return result


func cancel_recruitment() -> void:
	_recruitment_type = -1
	recruitment_spawn_tiles.clear()


func begin_bridge_build() -> bool:
	var unit := selected_unit()
	if not can_interact() or unit == null:
		return false
	if not _has_bridge_targets_for_mode(unit) or bridge_build_targets.is_empty():
		return false
	_bridge_mode = BridgeMode.BUILD
	_recruitment_type = -1
	recruitment_spawn_tiles.clear()
	return true


func begin_bridge_destroy() -> bool:
	var unit := selected_unit()
	if not can_interact() or unit == null:
		return false
	if not _has_bridge_targets_for_mode(unit) or bridge_destroy_targets.is_empty():
		return false
	_bridge_mode = BridgeMode.DESTROY
	_recruitment_type = -1
	recruitment_spawn_tiles.clear()
	return true


func bridge_action_at(tile: Vector2i) -> ActionResult:
	var unit := selected_unit()
	if not can_interact() or unit == null:
		return _failure("Not the local player's turn")
	if _bridge_mode == BridgeMode.NONE:
		return _failure("No bridge action is active")
	var action: GameAction
	if _bridge_mode == BridgeMode.BUILD:
		if tile not in bridge_build_targets:
			return _failure("Bridge target is not highlighted")
		action = BuildBridgeAction.new(unit.id, tile)
	else:
		if tile not in bridge_destroy_targets:
			return _failure("Bridge target is not highlighted")
		action = DestroyBridgeAction.new(unit.id, tile)
	var result := ActionResolver.resolve(state, action, view.exploration)
	last_result = result
	if result.success:
		_complete_action(action, result)
	return result


func cancel_bridge_action() -> void:
	_bridge_mode = BridgeMode.NONE


func bridge_mode() -> BridgeMode:
	return _bridge_mode


func recruitment_type() -> int:
	return _recruitment_type


func pass_available() -> bool:
	if not can_interact():
		return false
	if TurnManager.has_legal_move(view, local_player, view.exploration):
		return false
	if not available_recruitment_units().is_empty():
		return false
	return not _has_known_bridge_action()


func pass_turn() -> ActionResult:
	if not can_interact():
		return _failure("Not the local player's turn")
	var action := PassAction.new()
	var result := ActionResolver.resolve(state, action, view.exploration)
	last_result = result
	if result.success:
		_complete_action(action, result)
	return result


func can_offer_draw() -> bool:
	return not state.game_over and state.draw_offered_by == GameConfig.NO_PLAYER


func draw_offered_by_local() -> bool:
	return state.draw_offered_by == local_player


func incoming_draw_offer() -> bool:
	return state.draw_offered_by == int(GameConfig.opponent(local_player))


func offer_draw() -> bool:
	if not can_offer_draw():
		return false
	if not DrawSystem.offer_draw(state, local_player):
		return false
	_append_log("Player %d offered a draw." % local_player)
	refresh()
	return true


func accept_draw() -> bool:
	if not incoming_draw_offer():
		return false
	if not DrawSystem.accept_draw(state, local_player):
		return false
	_append_log("Draw agreed.")
	_clear_selection_state()
	refresh()
	return true


func decline_draw() -> bool:
	if not incoming_draw_offer():
		return false
	if not DrawSystem.decline_draw(state, local_player):
		return false
	_append_log("Draw declined.")
	refresh()
	return true


func gold(player: int) -> int:
	return state.get_gold(player)


func local_occupied_mine_count() -> int:
	var count := 0
	for mine: GoldMine in state.gold_mines:
		var unit := view.get_unit_at(mine.tile)
		if unit != null and unit.owner == local_player:
			count += 1
	return count


func explored_mine_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for mine: GoldMine in state.gold_mines:
		if view.knowledge.is_explored(mine.tile):
			tiles.append(mine.tile)
	return tiles


func visible_gold_token_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for mine: GoldMine in state.gold_mines:
		if mine.gold_available and view.knowledge.is_visible(mine.tile):
			tiles.append(mine.tile)
	return tiles


func get_unit_info(unit_id: int) -> Dictionary:
	var unit := _known_unit(unit_id)
	if unit == null:
		return {}
	var definition := unit.definition()
	var terrain_name := "Unknown"
	var data := view.board.get_tile(unit.tile)
	if data != null:
		terrain_name = TerrainRegistry.get_definition(data.terrain).display_name
	return {
		"id": unit.id,
		"type": int(unit.type),
		"name": definition.display_name,
		"owner": int(unit.owner),
		"vision": definition.base_vision,
		"can_capture": definition.can_capture,
		"price": definition.price,
		"movement_category": int(definition.movement_category),
		"base_reach": definition.base_reach,
		"explored_reach": definition.explored_reach,
		"can_build_bridges": definition.has_ability(UnitDefinition.Ability.BUILD_BRIDGES),
		"tile": unit.tile,
		"terrain": terrain_name,
	}


func selected_unit_info() -> Dictionary:
	if selected_unit_id == -1:
		return {}
	return get_unit_info(selected_unit_id)


func log_entries() -> Array[String]:
	return action_log.duplicate()


func append_public_log(message: String) -> void:
	if not message.is_empty():
		_append_log(message)


func _complete_action(action: GameAction, result: ActionResult) -> void:
	_clear_selection_state()
	refresh()
	_record_action(action, result)


func _record_action(action: GameAction, result: ActionResult) -> void:
	_append_log(action.describe())
	if result.captured_unit != null:
		_append_log(
			"Captured %s (P%d) at %s."
			% [
				UnitRegistry.get_definition(result.captured_unit.type).display_name,
				int(result.captured_unit.owner),
				str(result.captured_unit.tile),
			]
		)
	if result.ambushed:
		var ambusher_name := "a unit"
		if result.ambusher_type != -1:
			ambusher_name = UnitRegistry.get_definition(result.ambusher_type).display_name
		_append_log("Ambushed by %s at %s." % [ambusher_name, str(result.ambusher_tile)])
	elif result.move_result != null:
		if result.partial_move:
			_append_log("Move stopped short at %s." % str(result.move_result.final_tile))
		elif not result.moved:
			_append_log("No movement; the turn was consumed.")
	if result.recruited_unit != null:
		_append_log(
			"Recruited %s at %s."
			% [
				UnitRegistry.get_definition(result.recruited_unit.type).display_name,
				str(result.recruited_unit.tile),
			]
		)
	for player: int in result.gold_gained:
		_append_log("Player %d gained %d gold." % [player, int(result.gold_gained[player])])
	for tile: Vector2i in result.tokens_collected:
		if view.knowledge.is_explored(tile):
			_append_log("Collected a gold token at %s." % str(tile))
	for tile: Vector2i in result.tokens_spawned:
		if view.knowledge.is_visible(tile):
			_append_log("A gold token appeared at %s." % str(tile))
	if result.draw:
		_append_log("Draw: %s." % result.draw_reason)
	elif result.game_over:
		if result.winner != GameConfig.NO_PLAYER:
			_append_log("Player %d wins by King capture." % result.winner)


func _recompute_selection_highlights(unit: GameUnit) -> void:
	legal_destinations = MovementRules.legal_destinations(view, unit, view.exploration)
	capture_destinations.clear()
	for destination: Vector2i in legal_destinations:
		var target := view.get_unit_at(destination)
		if target != null and target.owner != local_player:
			capture_destinations.append(destination)
	bridge_build_targets.clear()
	bridge_destroy_targets.clear()
	if unit.definition().has_ability(UnitDefinition.Ability.BUILD_BRIDGES):
		for direction: Vector2i in BoardData.DIRECTIONS:
			var target := unit.tile + direction
			if BridgeRules.can_build(state, unit, target):
				bridge_build_targets.append(target)
			elif BridgeRules.can_destroy(state, unit, target):
				bridge_destroy_targets.append(target)


func _has_bridge_targets_for_mode(unit: GameUnit) -> bool:
	if _bridge_mode == BridgeMode.BUILD:
		return not bridge_build_targets.is_empty()
	if _bridge_mode == BridgeMode.DESTROY:
		return not bridge_destroy_targets.is_empty()
	return not bridge_build_targets.is_empty() or not bridge_destroy_targets.is_empty()


func _has_known_bridge_action() -> bool:
	for unit: GameUnit in view.get_units_for_player(local_player):
		if not unit.definition().has_ability(UnitDefinition.Ability.BUILD_BRIDGES):
			continue
		for direction: Vector2i in BoardData.DIRECTIONS:
			var target := unit.tile + direction
			if BridgeRules.can_build(state, unit, target):
				return true
			if BridgeRules.can_destroy(state, unit, target):
				return true
	return false


func _known_spawn_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile: Vector2i in state.get_deployment_tiles(local_player):
		if not view.board.is_playable(tile) or not view.board.is_passable(tile):
			continue
		if view.is_occupied(tile):
			continue
		tiles.append(tile)
	return tiles


func _known_unit(unit_id: int) -> GameUnit:
	return view.known_units.get(unit_id) as GameUnit


func _clear_move_highlights() -> void:
	legal_destinations.clear()
	capture_destinations.clear()
	bridge_build_targets.clear()
	bridge_destroy_targets.clear()


func _clear_selection_state() -> void:
	selected_tile = NO_TILE
	selected_unit_id = -1
	_clear_move_highlights()
	recruitment_spawn_tiles.clear()
	_recruitment_type = -1
	_bridge_mode = BridgeMode.NONE
	cancel_promotion()


func _append_log(message: String) -> void:
	action_log.append(message)
	while action_log.size() > MAX_LOG_ENTRIES:
		action_log.remove_at(0)


static func _failure(message: String) -> ActionResult:
	var result := ActionResult.new()
	result.error = message
	return result
