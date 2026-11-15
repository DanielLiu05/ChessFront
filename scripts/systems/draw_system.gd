class_name DrawSystem
extends RefCounted

const REASON_TURN_LIMIT: String = "turn_limit"
const REASON_THREEFOLD: String = "threefold_repetition"
const REASON_AGREEMENT: String = "agreement"
const REPETITIONS_TO_DRAW: int = 3


static func initialize(state) -> void:
	state.position_counts.clear()
	state.draw_offered_by = GameConfig.NO_PLAYER
	state.draw_reason = ""
	state.position_counts[position_key(state)] = 1


static func check_after_action(state) -> void:
	if state.game_over:
		return
	if state.ply >= state.turn_limit_plies:
		_end_draw(state, REASON_TURN_LIMIT)
		return
	var key := position_key(state)
	var count := int(state.position_counts.get(key, 0)) + 1
	state.position_counts[key] = count
	if count >= REPETITIONS_TO_DRAW:
		_end_draw(state, REASON_THREEFOLD)


static func position_key(state) -> String:
	var units: Array = []
	for unit: GameUnit in state.get_all_units():
		units.append([int(unit.owner), int(unit.type), unit.tile.x, unit.tile.y])
	units.sort_custom(_sort_units)

	var bridges: Array = []
	for tile: Vector2i in state.get_bridge_tiles():
		bridges.append([tile.x, tile.y])
	bridges.sort_custom(_sort_tiles)

	var mines: Array = []
	for mine: GoldMine in state.gold_mines:
		mines.append([
			mine.tile.x,
			mine.tile.y,
			mine.cycle_progress,
			1 if mine.gold_available else 0,
		])
	mines.sort_custom(_sort_mine_entries)

	var data := {
		"active_player": int(state.active_player),
		"bridges": bridges,
		"gold": [
			state.get_gold(GameConfig.Player.PLAYER_1),
			state.get_gold(GameConfig.Player.PLAYER_2),
		],
		"mines": mines,
		"units": units,
	}
	return JSON.stringify(data, "", true)


static func offer_draw(state, player: int) -> bool:
	if state.game_over:
		return false
	if player != GameConfig.Player.PLAYER_1 and player != GameConfig.Player.PLAYER_2:
		return false
	if state.draw_offered_by != GameConfig.NO_PLAYER:
		return false
	state.draw_offered_by = player
	return true


static func decline_draw(state, player: int) -> bool:
	if not _can_respond(state, player):
		return false
	state.draw_offered_by = GameConfig.NO_PLAYER
	return true


static func accept_draw(state, player: int) -> bool:
	if not _can_respond(state, player):
		return false
	_end_draw(state, REASON_AGREEMENT)
	return true


static func _can_respond(state, player: int) -> bool:
	if state.game_over or state.draw_offered_by == GameConfig.NO_PLAYER:
		return false
	return player == int(GameConfig.opponent(state.draw_offered_by))


static func _end_draw(state, reason: String) -> void:
	state.game_over = true
	state.winner = GameConfig.NO_PLAYER
	state.draw_reason = reason
	state.draw_offered_by = GameConfig.NO_PLAYER


static func _sort_units(a: Array, b: Array) -> bool:
	if int(a[3]) != int(b[3]):
		return int(a[3]) < int(b[3])
	if int(a[2]) != int(b[2]):
		return int(a[2]) < int(b[2])
	if int(a[0]) != int(b[0]):
		return int(a[0]) < int(b[0])
	return int(a[1]) < int(b[1])


static func _sort_tiles(a: Array, b: Array) -> bool:
	if int(a[1]) != int(b[1]):
		return int(a[1]) < int(b[1])
	return int(a[0]) < int(b[0])


static func _sort_mine_entries(a: Array, b: Array) -> bool:
	if int(a[1]) != int(b[1]):
		return int(a[1]) < int(b[1])
	return int(a[0]) < int(b[0])
