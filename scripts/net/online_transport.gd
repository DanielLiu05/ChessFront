class_name OnlineTransport
extends RefCounted

enum State {
	DISCONNECTED,
	CONNECTING,
	OPEN,
	CLOSED,
	FAILED,
}


func connect_to(_url: String) -> Error:
	return ERR_UNAVAILABLE


func poll(_delta: float) -> void:
	pass


func send_text(_text: String) -> Error:
	return ERR_UNAVAILABLE


func close() -> void:
	pass


func get_state() -> int:
	return State.DISCONNECTED


func take_messages() -> Array[String]:
	return []


func last_error() -> String:
	return ""
