extends TestCase


func test_envelope_round_trip() -> bool:
	var text := NetProtocol.encode(
		NetProtocol.MessageType.SUBMIT_ACTION,
		{"action": {"type": "pass"}},
		"request-1"
	)
	assert_false(text.is_empty(), "message encodes")
	var decoded := NetProtocol.decode(text)
	assert_true(decoded["ok"], "message decodes")
	if not decoded["ok"]:
		return true
	var envelope: Dictionary = decoded["envelope"]
	assert_eq(int(envelope["v"]), NetProtocol.PROTOCOL_VERSION, "version is recorded")
	assert_eq(int(envelope["type"]), int(NetProtocol.MessageType.SUBMIT_ACTION), "type is recorded")
	assert_eq(String(envelope["id"]), "request-1", "request id is recorded")
	assert_eq(envelope["payload"]["action"]["type"], "pass", "payload round-trips")
	return true


func test_decode_rejects_bad_envelopes() -> bool:
	var empty := NetProtocol.decode("")
	assert_false(empty["ok"], "empty message rejected")
	assert_eq(int(empty["error_code"]), int(NetProtocol.ErrorCode.BAD_MESSAGE), "empty code")

	var malformed := NetProtocol.decode("not json")
	assert_false(malformed["ok"], "malformed JSON rejected")
	assert_eq(int(malformed["error_code"]), int(NetProtocol.ErrorCode.BAD_MESSAGE), "malformed code")

	var wrong_version := NetProtocol.decode(
		JSON.stringify({"v": NetProtocol.PROTOCOL_VERSION + 1, "type": 0, "payload": {}})
	)
	assert_false(wrong_version["ok"], "wrong version rejected")
	assert_eq(
		int(wrong_version["error_code"]),
		int(NetProtocol.ErrorCode.VERSION_MISMATCH),
		"version code"
	)

	var unknown_type := NetProtocol.decode(
		JSON.stringify({"v": NetProtocol.PROTOCOL_VERSION, "type": 999, "payload": {}})
	)
	assert_false(unknown_type["ok"], "unknown type rejected")
	assert_eq(
		int(unknown_type["error_code"]),
		int(NetProtocol.ErrorCode.UNKNOWN_TYPE),
		"unknown type code"
	)

	var bad_payload := NetProtocol.decode(
		JSON.stringify({"v": NetProtocol.PROTOCOL_VERSION, "type": 0, "payload": []})
	)
	assert_false(bad_payload["ok"], "non-object payload rejected")

	var bad_id := NetProtocol.decode(
		JSON.stringify({"v": NetProtocol.PROTOCOL_VERSION, "type": 0, "payload": {}, "id": 4})
	)
	assert_false(bad_id["ok"], "non-string id rejected")
	return true


func test_oversized_messages_are_rejected() -> bool:
	var payload := {"text": "a".repeat(NetProtocol.MAX_MESSAGE_BYTES)}
	var encoded := NetProtocol.encode(NetProtocol.MessageType.PING, payload)
	assert_true(encoded.is_empty(), "oversized encode returns no message")
	var decoded := NetProtocol.decode("a".repeat(NetProtocol.MAX_MESSAGE_BYTES + 1))
	assert_false(decoded["ok"], "oversized decode rejected")
	assert_eq(int(decoded["error_code"]), int(NetProtocol.ErrorCode.OVERSIZED), "oversized code")
	return true


func test_error_message_and_tokens() -> bool:
	var text := NetProtocol.encode_error(
		NetProtocol.ErrorCode.ROOM_FULL,
		"Room is full",
		"request-2"
	)
	var decoded := NetProtocol.decode(text)
	assert_true(decoded["ok"], "error envelope decodes")
	var envelope: Dictionary = decoded["envelope"]
	assert_eq(int(envelope["type"]), int(NetProtocol.MessageType.ERROR), "error type")
	assert_eq(
		int(envelope["payload"]["code"]),
		int(NetProtocol.ErrorCode.ROOM_FULL),
		"error code payload"
	)
	assert_eq(String(envelope["payload"]["message"]), "Room is full", "error text")
	assert_eq(String(envelope["id"]), "request-2", "error request id")

	var first := NetProtocol.generate_player_token()
	var second := NetProtocol.generate_player_token()
	assert_eq(first.length(), 32, "token is 128-bit hex")
	assert_ne(first, second, "tokens differ")
	for index in first.length():
		assert_true(
			"0123456789abcdef".find(first.substr(index, 1)) != -1,
			"token is hex"
		)
	return true


func test_room_codes() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var first := RoomCode.generate(rng)
	var second_rng := RandomNumberGenerator.new()
	second_rng.seed = 424242
	var second := RoomCode.generate(second_rng)
	assert_eq(first, second, "room-code generation is deterministic under a seed")
	assert_eq(first.length(), RoomCode.LENGTH, "room-code length")
	assert_true(RoomCode.is_valid(first), "generated code is valid")
	assert_eq(RoomCode.normalize("  abcd23  "), "ABCD23", "code normalization")
	assert_true(RoomCode.is_valid("abcd23"), "normalized lowercase code is valid")
	assert_false(RoomCode.is_valid("ABCD2"), "short code is invalid")
	assert_false(RoomCode.is_valid("ABCDO0"), "ambiguous characters are invalid")
	assert_false(RoomCode.is_valid("ABCDE!"), "non-alphabet characters are invalid")
	return true
