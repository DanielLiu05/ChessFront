class_name OnlineConnection
extends RefCounted

var id: String = ""
var handshaken: bool = false
var room_code: String = ""
var token: String = ""
var player: int = GameConfig.NO_PLAYER
var connected: bool = true
var last_seen_at: float = 0.0
var window_started_at: float = 0.0
var window_message_count: int = 0
var awaiting_pong: bool = false
var ping_sent_at: float = 0.0


func _init(connection_id: String = "") -> void:
	id = connection_id


func bind(room_code_value: String, player_token: String) -> void:
	room_code = room_code_value
	token = player_token


func clear_binding() -> void:
	room_code = ""
	token = ""
	player = GameConfig.NO_PLAYER
