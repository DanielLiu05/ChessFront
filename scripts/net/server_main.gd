extends SceneTree

const DEFAULT_PORT: int = 9000
const DEFAULT_BIND: String = "127.0.0.1"

var _host: WebSocketServerHost
var _last_ms: int = 0


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	var port := DEFAULT_PORT
	var bind := DEFAULT_BIND
	var grace_seconds := -1.0
	var index := 0
	while index < arguments.size():
		var argument := arguments[index]
		if argument == "--port" and index + 1 < arguments.size():
			port = int(arguments[index + 1])
			index += 1
		elif argument == "--bind" and index + 1 < arguments.size():
			bind = arguments[index + 1]
			index += 1
		elif argument == "--grace-seconds" and index + 1 < arguments.size():
			grace_seconds = float(arguments[index + 1])
			index += 1
		index += 1
	_host = WebSocketServerHost.new()
	if grace_seconds > 0.0:
		_host.server.grace_seconds = grace_seconds
	var error := _host.start(port, bind)
	if error != OK:
		push_error("Could not start the online server on %s:%d (error %d)" % [bind, port, error])
		quit(1)
		return
	print("Chessfront online server listening on ws://%s:%d" % [bind, _host.port])
	print("Protocol version %d; rooms are in memory only" % NetProtocol.PROTOCOL_VERSION)
	_last_ms = Time.get_ticks_msec()
	process_frame.connect(_on_frame)


func _finalize() -> void:
	if _host != null:
		_host.stop()


func _on_frame() -> void:
	var now := Time.get_ticks_msec()
	var delta := float(now - _last_ms) / 1000.0
	_last_ms = now
	_host.poll(delta)
