class_name FakeOnlineTransport
extends OnlineTransport

var url: String = ""
var sent: Array[String] = []
var connect_count: int = 0
var auto_open: bool = true
var connect_error: Error = OK

var _state: int = State.DISCONNECTED
var _messages: Array[String] = []
var _error: String = ""


func connect_to(target_url: String) -> Error:
	url = target_url
	connect_count += 1
	_messages.clear()
	_error = ""
	if connect_error != OK:
		_state = State.FAILED
		_error = "Fake connection error %d" % connect_error
		return connect_error
	_state = State.OPEN if auto_open else State.CONNECTING
	return OK


func poll(_delta: float) -> void:
	pass


func send_text(text: String) -> Error:
	if _state != State.OPEN:
		return ERR_UNCONFIGURED
	sent.append(text)
	return OK


func close() -> void:
	_state = State.CLOSED


func get_state() -> int:
	return _state


func take_messages() -> Array[String]:
	var messages := _messages.duplicate()
	_messages.clear()
	return messages


func last_error() -> String:
	return _error


func simulate_open() -> void:
	_state = State.OPEN


func simulate_close(reason: String = "closed") -> void:
	_state = State.CLOSED
	_error = reason


func push(type: int, payload: Dictionary, request_id: String = "") -> void:
	_messages.append(NetProtocol.encode(type, payload, request_id))


func push_text(text: String) -> void:
	_messages.append(text)


func last_sent() -> Dictionary:
	if sent.is_empty():
		return {}
	return NetProtocol.decode(sent[sent.size() - 1])


func sent_type_count(type: int) -> int:
	var count := 0
	for text: String in sent:
		var decoded := NetProtocol.decode(text)
		if decoded["ok"] and int(decoded["envelope"]["type"]) == type:
			count += 1
	return count


func clear_sent() -> void:
	sent.clear()
