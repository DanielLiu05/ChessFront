class_name NetProtocol
extends RefCounted

const PROTOCOL_VERSION: int = 1
const MAX_MESSAGE_BYTES: int = 65536

enum MessageType {
	HELLO,
	WELCOME,
	CREATE_ROOM,
	ROOM_CREATED,
	JOIN_ROOM,
	ROOM_JOINED,
	RESUME_ROOM,
	LEAVE_ROOM,
	SELECT_MAP,
	START_MATCH,
	MATCH_STARTED,
	SUBMIT_ACTION,
	ACTION_RESULT,
	STATE,
	EVENT,
	OFFER_DRAW,
	ACCEPT_DRAW,
	DECLINE_DRAW,
	RETURN_TO_LOBBY,
	ROOM_STATE,
	ERROR,
	PING,
	PONG,
}

enum ErrorCode {
	NONE,
	BAD_MESSAGE,
	VERSION_MISMATCH,
	UNKNOWN_TYPE,
	OVERSIZED,
	INVALID_FIELD,
	ROOM_NOT_FOUND,
	ROOM_FULL,
	INVALID_TOKEN,
	NOT_IN_ROOM,
	NOT_OWNER,
	NOT_YOUR_TURN,
	STALE_ACTION,
	ACTION_REJECTED,
	PROTOCOL_ERROR,
}


static func is_known_type(type: int) -> bool:
	return type >= int(MessageType.HELLO) and type <= int(MessageType.PONG)


static func encode(type: int, payload: Dictionary = {}, request_id: String = "") -> String:
	if not is_known_type(type):
		return ""
	if not request_id.is_empty() and request_id.length() > 128:
		return ""
	var envelope: Dictionary = {
		"v": PROTOCOL_VERSION,
		"type": type,
		"payload": payload,
	}
	if not request_id.is_empty():
		envelope["id"] = request_id
	var text := JSON.stringify(envelope)
	if text.to_utf8_buffer().size() > MAX_MESSAGE_BYTES:
		return ""
	return text


static func decode(text: String) -> Dictionary:
	if text.is_empty():
		return _failure(ErrorCode.BAD_MESSAGE, "Empty message")
	if text.to_utf8_buffer().size() > MAX_MESSAGE_BYTES:
		return _failure(ErrorCode.OVERSIZED, "Message exceeds the size limit")
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _failure(ErrorCode.BAD_MESSAGE, "Message is not a JSON object")
	var raw: Dictionary = parsed
	var version_value: Variant = raw.get("v")
	if not _is_integer(version_value):
		return _failure(ErrorCode.BAD_MESSAGE, "Message has no integer version")
	var version := int(version_value)
	if version != PROTOCOL_VERSION:
		return _failure(
			ErrorCode.VERSION_MISMATCH,
			"Protocol version %d does not match %d" % [version, PROTOCOL_VERSION]
		)
	var type_value: Variant = raw.get("type")
	if not _is_integer(type_value):
		return _failure(ErrorCode.BAD_MESSAGE, "Message has no integer type")
	var type := int(type_value)
	if not is_known_type(type):
		return _failure(ErrorCode.UNKNOWN_TYPE, "Unknown message type %d" % type)
	var payload_value: Variant = raw.get("payload", {})
	if typeof(payload_value) != TYPE_DICTIONARY:
		return _failure(ErrorCode.BAD_MESSAGE, "Message payload is not an object")
	var request_id: String = ""
	if raw.has("id"):
		if typeof(raw["id"]) != TYPE_STRING:
			return _failure(ErrorCode.BAD_MESSAGE, "Message id is not a string")
		request_id = String(raw["id"])
		if request_id.length() > 128:
			return _failure(ErrorCode.BAD_MESSAGE, "Message id is too long")
	return {
		"ok": true,
		"error": "",
		"error_code": ErrorCode.NONE,
		"envelope": {
			"v": version,
			"type": type,
			"id": request_id,
			"payload": payload_value,
		},
	}


static func encode_error(code: int, message: String, request_id: String = "") -> String:
	return encode(MessageType.ERROR, {"code": code, "message": message}, request_id)


static func generate_player_token() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


static func _failure(code: int, message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message,
		"error_code": code,
		"envelope": {},
	}


static func _is_integer(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) == TYPE_FLOAT:
		var number := float(value)
		return is_finite(number) and number == floorf(number)
	return false
