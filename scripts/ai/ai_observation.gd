class_name AiObservation
extends RefCounted

var player: int = GameConfig.NO_PLAYER
var view: PlayerView
var gold: int = 0
var turn_limit_plies: int = GameConfig.DEFAULT_TURN_LIMIT_PLIES
var ply: int = 0
var map_id: String = ""


static func for_player(state: GameState, ai_player: int) -> AiObservation:
	var observation := AiObservation.new()
	observation.player = ai_player
	observation.view = PlayerView.for_player(state, ai_player)
	observation.gold = state.get_gold(ai_player)
	observation.turn_limit_plies = state.turn_limit_plies
	observation.ply = state.ply
	observation.map_id = state.map_id
	return observation
