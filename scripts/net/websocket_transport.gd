class_name WebSocketTransport
extends OnlineTransport

var _peer: WebSocketPeer
var _messages: Array[String] = []
var _state: int = State.DISCONNECTED
var _error: String = ""


func connect_to(url: String) -> Error:
	_messages.clear()
	_error = ""
	_peer = WebSocketPeer.new()
	var error := _peer.connect_to_url(url)
	if error != OK:
		_state = State.FAILED
		_error = "Could not connect to %s (error %d)" % [url, error]
		return error
	_state = State.CONNECTING
	return OK


func poll(_delta: float) -> void:
	if _peer == null:
		return
	_peer.poll()
	var peer_state := _peer.get_ready_state()
	match peer_state:
		WebSocketPeer.STATE_CONNECTING:
			if _state != State.FAILED:
				_state = State.CONNECTING
		WebSocketPeer.STATE_OPEN:
			_state = State.OPEN
		WebSocketPeer.STATE_CLOSING:
			_state = State.CLOSED
		WebSocketPeer.STATE_CLOSED:
			if _state != State.FAILED:
				_state = State.CLOSED
				var reason := _peer.get_close_reason()
				if not reason.is_empty():
					_error = reason
			return
	while _peer.get_available_packet_count() > 0:
		var packet := _peer.get_packet()
		if packet.is_empty():
			continue
		_messages.append(packet.get_string_from_utf8())


func send_text(text: String) -> Error:
	if _peer == null or _peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return ERR_UNCONFIGURED
	return _peer.send_text(text)


func close() -> void:
	if _peer != null and _peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_peer.close(1000, "Client closed")
	_state = State.CLOSED


func get_state() -> int:
	return _state


func take_messages() -> Array[String]:
	var messages := _messages.duplicate()
	_messages.clear()
	return messages


func last_error() -> String:
	return _error
