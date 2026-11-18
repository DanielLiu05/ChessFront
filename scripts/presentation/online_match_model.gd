class_name OnlineMatchModel
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

var state: ClientMatchState
var view: PlayerView
var local_player: int = GameConfig.NO_PLAYER
var ai_player: int = GameConfig.NO_PLAYER

var selected_tile: Vector2i = NO_TILE
var selected_unit_id: int = -1
var legal_destinations: Array[Vector2i] = []
var capture_destinations: Array[Vector2i] = []
var bridge_build_targets: Array[Vector2i] = []
var bridge_destroy_targets: Array[Vector2i] = []
var recruitment_spawn_tiles: Array[Vector2i] = []
var pending_promotion_tile: Vector2i = NO_TILE
var pending_promotion_unit_id: int = -1
var action_log: Array[String] = []

var _recruitment_type: int = -1
var _bridge_mode: int = BridgeMode.NONE
var _pending_action: GameAction


func _init(client_state: ClientMatchState) -> void:
	state = client_state
	refresh()


func refresh() -> void:
	if state == null:
		return
	local_player = state.local_player
	view = state.view
	cancel_promotion()
	_recruitment_type = -1
	recruitment_spawn_tiles.clear()
	_bridge_mode = BridgeMode.NONE
	_pending_action = null
	_clear_selection_state()


func can_interact() -> bool:
	return state != null and state.can_act()


func side_label(player: int) -> String:
	return "You" if player == local_player else "Opponent"


func short_side_label(player: int) -> String:
	return "You" if player == local_player else "Opp"


func winner_text() -> String:
	if state == null or not state.game_over:
		return ""
	if state.winner == GameConfig.NO_PLAYER:
		return "Draw"
	return "You win" if state.winner == local_player else "Opponent wins"


func gold_summary() -> String:
	return "Gold You %d · Opponent ?" % own_gold()


func has_pending_promotion() -> bool:
	return pending_promotion_unit_id != -1


func selected_unit() -> GameUnit:
	if selected_unit_id == -1 or view == null:
		return null
	var unit := view.known_units.get(selected_unit_id) as GameUnit
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


func click_tile(tile: Vector2i) -> int:
	if not can_interact() or has_pending_promotion():
		return ClickResult.IGNORED
	if _recruitment_type != -1:
		if tile not in recruitment_spawn_tiles:
			return ClickResult.IGNORED
		_pending_action = RecruitAction.new(_recruitment_type, tile)
		return ClickResult.ACTION_OK
	if _bridge_mode != BridgeMode.NONE:
		var targets := bridge_build_targets if _bridge_mode == BridgeMode.BUILD else bridge_destroy_targets
		if tile not in targets:
			return ClickResult.IGNORED
		var unit := selected_unit()
		if unit == null:
			return ClickResult.REJECTED
		_pending_action = (
			BuildBridgeAction.new(unit.id, tile)
			if _bridge_mode == BridgeMode.BUILD
			else DestroyBridgeAction.new(unit.id, tile)
		)
		return ClickResult.ACTION_OK
	var unit := selected_unit()
	if unit != null and tile in legal_destinations:
		if MovementRules.requires_promotion(unit, tile):
			pending_promotion_unit_id = unit.id
			pending_promotion_tile = tile
			return ClickResult.PROMOTION_REQUIRED
		_pending_action = MoveAction.new(unit.id, tile, UnitType.Type.QUEEN)
		return ClickResult.ACTION_OK
	var clicked := view.get_unit_at(tile)
	if clicked != null and clicked.owner == local_player:
		select_unit_at(tile)
		return ClickResult.SELECTED
	_clear_selection_state()
	return ClickResult.DESELECTED


func complete_promotion_action(promotion_type: int) -> GameAction:
	if not has_pending_promotion() or not MovementRules.is_valid_promotion_type(promotion_type):
		return null
	var action := MoveAction.new(
		pending_promotion_unit_id,
		pending_promotion_tile,
		promotion_type
	)
	cancel_promotion()
	_clear_selection_state()
	return action


func cancel_promotion() -> void:
	pending_promotion_unit_id = -1
	pending_promotion_tile = NO_TILE


func available_recruitment_units() -> Array[int]:
	var types: Array[int] = []
	if not can_interact() or _known_spawn_tiles().is_empty():
		return types
	for unit_type: int in UnitRegistry.get_all_types():
		var definition := UnitRegistry.get_definition(unit_type)
		if definition.purchasable and definition.price <= own_gold():
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
	if definition.price > own_gold():
		return false
	return not _known_spawn_tiles().is_empty()


func begin_recruitment(unit_type: int) -> bool:
	if not can_recruit_unit(unit_type):
		return false
	_recruitment_type = unit_type
	_bridge_mode = BridgeMode.NONE
	_clear_selection_state()
	recruitment_spawn_tiles = _known_spawn_tiles()
	return not recruitment_spawn_tiles.is_empty()


func cancel_recruitment() -> void:
	_recruitment_type = -1
	recruitment_spawn_tiles.clear()


func begin_bridge_build() -> bool:
	var unit := selected_unit()
	if not can_interact() or unit == null:
		return false
	if bridge_build_targets.is_empty():
		return false
	_bridge_mode = BridgeMode.BUILD
	_recruitment_type = -1
	recruitment_spawn_tiles.clear()
	return true


func begin_bridge_destroy() -> bool:
	var unit := selected_unit()
	if not can_interact() or unit == null:
		return false
	if bridge_destroy_targets.is_empty():
		return false
	_bridge_mode = BridgeMode.DESTROY
	_recruitment_type = -1
	recruitment_spawn_tiles.clear()
	return true


func cancel_bridge_action() -> void:
	_bridge_mode = BridgeMode.NONE


func bridge_mode() -> int:
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
	return not BridgeRules.has_legal_bridge_action(view, local_player)


func pass_action() -> GameAction:
	if not pass_available():
		return null
	_clear_selection_state()
	return PassAction.new()


func consume_action() -> GameAction:
	var action := _pending_action
	_pending_action = null
	_recruitment_type = -1
	recruitment_spawn_tiles.clear()
	_bridge_mode = BridgeMode.NONE
	cancel_promotion()
	_clear_selection_state()
	return action


func can_offer_draw() -> bool:
	return state != null and not state.game_over and state.draw_offered_by == GameConfig.NO_PLAYER


func draw_offered_by_local() -> bool:
	return state != null and state.draw_offered_by == local_player


func incoming_draw_offer() -> bool:
	return state != null and state.draw_offered_by != GameConfig.NO_PLAYER \
		and state.draw_offered_by != local_player


func has_state() -> bool:
	return state != null


func is_game_over() -> bool:
	return state != null and state.game_over


func game_winner() -> int:
	return state.winner if state != null else GameConfig.NO_PLAYER


func game_draw_reason() -> String:
	return state.draw_reason if state != null else ""


func active_player() -> int:
	return state.active_player if state != null else GameConfig.NO_PLAYER


func ply() -> int:
	return state.ply if state != null else 0


func turn_limit_plies() -> int:
	return state.turn_limit_plies if state != null else GameConfig.DEFAULT_TURN_LIMIT_PLIES


func draw_offered_by() -> int:
	return state.draw_offered_by if state != null else GameConfig.NO_PLAYER


func own_gold() -> int:
	return state.own_gold if state != null else 0


func gold(player: int) -> int:
	return own_gold() if player == local_player else -1


func local_occupied_mine_count() -> int:
	if state == null or view == null:
		return 0
	var count := 0
	for tile: Vector2i in state.known_mines:
		var unit := view.get_unit_at(tile)
		if unit != null and unit.owner == local_player:
			count += 1
	return count


func explored_mine_tiles() -> Array[Vector2i]:
	if state == null:
		return []
	var tiles: Array[Vector2i] = []
	tiles.append_array(state.known_mines)
	return tiles


func visible_gold_token_tiles() -> Array[Vector2i]:
	if state == null:
		return []
	var tiles: Array[Vector2i] = []
	tiles.append_array(state.visible_gold_token_tiles)
	return tiles


func get_unit_info(unit_id: int) -> Dictionary:
	if view == null:
		return {}
	var unit := view.known_units.get(unit_id) as GameUnit
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
	if message.is_empty():
		return
	action_log.append(message)
	if action_log.size() > MAX_LOG_ENTRIES:
		action_log.remove_at(0)


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
			if BridgeRules.can_build(view, unit, target):
				bridge_build_targets.append(target)
			elif BridgeRules.can_destroy(view, unit, target):
				bridge_destroy_targets.append(target)


func _known_spawn_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	if view == null:
		return tiles
	for tile: Vector2i in view.deployment_tiles:
		if not view.board.is_playable(tile) or not view.board.is_passable(tile):
			continue
		if view.is_occupied(tile):
			continue
		tiles.append(tile)
	return tiles


func _clear_selection_state() -> void:
	selected_tile = NO_TILE
	selected_unit_id = -1
	legal_destinations.clear()
	capture_destinations.clear()
	bridge_build_targets.clear()
	bridge_destroy_targets.clear()
