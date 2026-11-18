class_name ServerRoom
extends OnlineRoomState

var map: MapData
var state: GameState
var match_number: int = 0
var assignment_history: Array[Dictionary] = []
var last_action_id: String = ""
var seen_action_ids: Dictionary[String, bool] = {}
var paused: bool = false
var paused_token: String = ""
var grace_deadline: float = 0.0
var rematch_votes: Dictionary[int, bool] = {}
var created_at: float = 0.0
var last_activity_at: float = 0.0


func _init(room_code: String, created: float = 0.0) -> void:
	super(room_code)
	created_at = created
	last_activity_at = created


func touch(now: float) -> void:
	last_activity_at = now


func begin_match() -> void:
	phase = Phase.MATCH
	paused = false
	paused_token = ""
	grace_deadline = 0.0
	pending_request.clear()
	rematch_votes.clear()
	seen_action_ids.clear()
	last_action_id = ""


func reset_to_lobby() -> void:
	phase = Phase.LOBBY
	paused = false
	paused_token = ""
	grace_deadline = 0.0
	pending_request.clear()
	rematch_votes.clear()
	seen_action_ids.clear()
	last_action_id = ""
	state = null
	map = null
	map_id = ""
	first_player = GameConfig.NO_PLAYER
	player_by_token.clear()


func to_summary() -> Dictionary:
	var summary := super.to_summary()
	summary["match_number"] = match_number
	summary["paused"] = paused
	return summary
