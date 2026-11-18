class_name WebSocketServerHost
extends RefCounted

var server: OnlineServer
var port: int = 0
var bind_address: String = "127.0.0.1"

var _tcp: TCPServer
var _peers: Dictionary[int, WebSocketPeer] = {}
var _queued_text: Dictionary[int, Array] = {}
var _next_peer_id: int = 1


func _init(online_server: OnlineServer = null) -> void:
	server = online_server if online_server != null else OnlineServer.new()
	server.sender = _send
	server.closer = _close_peer


func start(port_number: int = 9000, address: String = "127.0.0.1") -> Error:
	_tcp = TCPServer.new()
	var error := _tcp.listen(port_number, address)
	if error != OK:
		return error
	port = _tcp.get_local_port()
	bind_address = address
	return OK


func is_listening() -> bool:
	return _tcp != null and _tcp.is_listening()


func stop() -> void:
	for id: int in _peers.keys():
		var peer := _peers[id] as WebSocketPeer
		if peer != null:
			peer.close(1001, "Server shutting down")
	_peers.clear()
	_queued_text.clear()
	if _tcp != null:
		_tcp.stop()
	_tcp = null


func poll(delta: float) -> void:
	if _tcp == null:
		return
	_accept_connections()
	var closed: Array[int] = []
	for id: int in _peers.keys():
		var peer := _peers[id] as WebSocketPeer
		peer.poll()
		var state := peer.get_ready_state()
		if state == WebSocketPeer.STATE_CLOSED:
			closed.append(id)
			continue
		if state != WebSocketPeer.STATE_OPEN:
			continue
		_flush_queue(id, peer)
		while peer.get_available_packet_count() > 0:
			var packet := peer.get_packet()
			if not peer.was_string_packet():
				continue
			server.handle_text(str(id), packet.get_string_from_utf8())
	for id: int in closed:
		_peers.erase(id)
		_queued_text.erase(id)
		server.remove_client(str(id))
	server.poll(delta)


func peer_count() -> int:
	return _peers.size()


func _accept_connections() -> void:
	while _tcp.is_connection_available():
		var stream := _tcp.take_connection()
		if stream == null:
			continue
		var peer := WebSocketPeer.new()
		if peer.accept_stream(stream) != OK:
			continue
		var id := _next_peer_id
		_next_peer_id += 1
		_peers[id] = peer
		if not server.add_client(str(id)):
			peer.close(1013, "Server is at capacity")
			_peers.erase(id)
			_queued_text.erase(id)


func _send(client_id: String, text: String) -> void:
	var id := int(client_id)
	var peer := _peers.get(id) as WebSocketPeer
	if peer == null:
		return
	if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		peer.send_text(text)
		return
	var queue: Array = _queued_text.get(id, [])
	queue.append(text)
	_queued_text[id] = queue


func _flush_queue(id: int, peer: WebSocketPeer) -> void:
	if not _queued_text.has(id):
		return
	var queue: Array = _queued_text[id]
	_queued_text.erase(id)
	for text: String in queue:
		peer.send_text(text)


func _close_peer(client_id: String, reason: String) -> void:
	var peer := _peers.get(int(client_id)) as WebSocketPeer
	if peer != null:
		peer.close(1008, reason)
