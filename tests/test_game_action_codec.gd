extends TestCase


func test_all_action_types_round_trip() -> bool:
	var move := MoveAction.new(7, Vector2i(4, 5), UnitType.Type.KNIGHT)
	var move_data := GameActionCodec.encode(move)
	assert_eq(String(move_data["type"]), GameActionCodec.TYPE_MOVE, "move tag")
	var decoded_move := GameActionCodec.decode(move_data) as MoveAction
	assert_not_null(decoded_move, "move decodes")
	if decoded_move != null:
		assert_eq(decoded_move.unit_id, 7, "move unit id")
		assert_eq(decoded_move.destination, Vector2i(4, 5), "move destination")
		assert_eq(decoded_move.promotion_type, UnitType.Type.KNIGHT, "move promotion")

	var recruit := RecruitAction.new(UnitType.Type.ENGINEER, Vector2i(3, 14))
	var recruit_data := GameActionCodec.encode(recruit)
	assert_eq(String(recruit_data["type"]), GameActionCodec.TYPE_RECRUIT, "recruit tag")
	var decoded_recruit := GameActionCodec.decode(recruit_data) as RecruitAction
	assert_not_null(decoded_recruit, "recruit decodes")
	if decoded_recruit != null:
		assert_eq(decoded_recruit.unit_type, UnitType.Type.ENGINEER, "recruit type")
		assert_eq(decoded_recruit.spawn_tile, Vector2i(3, 14), "recruit tile")

	var build := BuildBridgeAction.new(9, Vector2i(8, 7))
	var build_data := GameActionCodec.encode(build)
	assert_eq(String(build_data["type"]), GameActionCodec.TYPE_BUILD_BRIDGE, "build tag")
	var decoded_build := GameActionCodec.decode(build_data) as BuildBridgeAction
	assert_not_null(decoded_build, "build decodes")
	if decoded_build != null:
		assert_eq(decoded_build.engineer_id, 9, "build engineer")
		assert_eq(decoded_build.target_tile, Vector2i(8, 7), "build tile")

	var destroy := DestroyBridgeAction.new(10, Vector2i(8, 7))
	var destroy_data := GameActionCodec.encode(destroy)
	assert_eq(String(destroy_data["type"]), GameActionCodec.TYPE_DESTROY_BRIDGE, "destroy tag")
	var decoded_destroy := GameActionCodec.decode(destroy_data) as DestroyBridgeAction
	assert_not_null(decoded_destroy, "destroy decodes")
	if decoded_destroy != null:
		assert_eq(decoded_destroy.engineer_id, 10, "destroy engineer")
		assert_eq(decoded_destroy.target_tile, Vector2i(8, 7), "destroy tile")

	var pass_data := GameActionCodec.encode(PassAction.new())
	assert_eq(String(pass_data["type"]), GameActionCodec.TYPE_PASS, "pass tag")
	assert_true(GameActionCodec.decode(pass_data) is PassAction, "pass decodes")
	return true


func test_invalid_actions_are_rejected() -> bool:
	assert_true(GameActionCodec.encode(null).is_empty(), "null action is rejected")
	assert_true(
		GameActionCodec.encode(MoveAction.new(0, Vector2i(1, 1))).is_empty(),
		"zero unit id is rejected"
	)
	assert_true(
		GameActionCodec.encode(MoveAction.new(1, Vector2i(16, 0))).is_empty(),
		"out-of-bounds move is rejected"
	)
	assert_true(
		GameActionCodec.encode(
			MoveAction.new(1, Vector2i(1, 1), UnitType.Type.PAWN)
		).is_empty(),
		"invalid promotion is rejected"
	)
	assert_true(
		GameActionCodec.encode(
			RecruitAction.new(UnitType.Type.QUEEN, Vector2i(1, 1))
		).is_empty(),
		"unpurchasable recruit is rejected"
	)
	assert_true(
		GameActionCodec.encode(RecruitAction.new(99, Vector2i(1, 1))).is_empty(),
		"unknown recruit type is rejected"
	)
	assert_true(
		GameActionCodec.encode(BuildBridgeAction.new(0, Vector2i(1, 1))).is_empty(),
		"zero bridge engineer is rejected"
	)
	return true


func test_malformed_action_data_is_rejected() -> bool:
	assert_null(GameActionCodec.decode({}), "empty action is rejected")
	assert_null(
		GameActionCodec.decode({"type": "unknown"}),
		"unknown action type is rejected"
	)
	assert_null(
		GameActionCodec.decode(
			{"type": "move", "unit_id": 1, "destination": [4, 5]}
		),
		"missing promotion is rejected"
	)
	assert_null(
		GameActionCodec.decode(
			{"type": "move", "unit_id": "1", "destination": [4, 5], "promotion_type": 2}
		),
		"string unit id is rejected"
	)
	assert_null(
		GameActionCodec.decode(
			{"type": "move", "unit_id": 1, "destination": ["4", 5], "promotion_type": 2}
		),
		"string coordinate is rejected"
	)
	assert_null(
		GameActionCodec.decode(
			{"type": "recruit", "unit_type": 99, "spawn_tile": [3, 14]}
		),
		"unknown recruit type data is rejected"
	)
	return true


func test_json_number_forms_are_accepted() -> bool:
	var decoded := GameActionCodec.decode(
		{
			"type": "move",
			"unit_id": 3.0,
			"destination": [4.0, 5.0],
			"promotion_type": 2.0,
		}
	) as MoveAction
	assert_not_null(decoded, "integral JSON numbers decode")
	if decoded != null:
		assert_eq(decoded.unit_id, 3, "numeric unit id")
		assert_eq(decoded.destination, Vector2i(4, 5), "numeric destination")
		assert_eq(decoded.promotion_type, UnitType.Type.ROOK, "numeric promotion")
	return true
