extends TestCase


func test_standard_board_dimensions() -> bool:
	assert_eq(GameConfig.BOARD_WIDTH, 16, "board width")
	assert_eq(GameConfig.BOARD_HEIGHT, 16, "board height")
	assert_eq(GameConfig.STANDARD_ROW_WIDTHS.size(), GameConfig.BOARD_HEIGHT, "one width per row")
	var total := 0
	for width: int in GameConfig.STANDARD_ROW_WIDTHS:
		total += width
	assert_eq(total, 216, "standard mask tile count")
	return true


func test_standard_rows_are_mirrored() -> bool:
	for row in GameConfig.BOARD_HEIGHT:
		assert_eq(
			GameConfig.STANDARD_ROW_WIDTHS[row],
			GameConfig.STANDARD_ROW_WIDTHS[GameConfig.BOARD_HEIGHT - 1 - row],
			"row %d mirrors its opposite" % row
		)
	return true


func test_mirror_tile_is_an_involution() -> bool:
	var tile := Vector2i(4, 0)
	assert_eq(GameConfig.mirror_tile(tile), Vector2i(11, 15), "mirror of (4, 0)")
	assert_eq(GameConfig.mirror_tile(GameConfig.mirror_tile(tile)), tile, "mirror twice")
	return true


func test_player_ends() -> bool:
	assert_eq(GameConfig.FIRST_PLAYER, GameConfig.Player.PLAYER_1, "player 1 moves first")
	assert_eq(GameConfig.PLIES_PER_ROUND, 2, "two plies per round")
	assert_eq(GameConfig.opponent(GameConfig.Player.PLAYER_1), GameConfig.Player.PLAYER_2, "player 1 opponent")
	assert_eq(GameConfig.opponent(GameConfig.Player.PLAYER_2), GameConfig.Player.PLAYER_1, "player 2 opponent")
	assert_eq(GameConfig.forward_row_delta(GameConfig.Player.PLAYER_1), -1, "player 1 moves up")
	assert_eq(GameConfig.forward_row_delta(GameConfig.Player.PLAYER_2), 1, "player 2 moves down")
	assert_eq(GameConfig.home_row_range(GameConfig.Player.PLAYER_1), Vector2i(8, 15), "player 1 home half")
	assert_eq(GameConfig.home_row_range(GameConfig.Player.PLAYER_2), Vector2i(0, 7), "player 2 home half")
	assert_eq(GameConfig.deployment_row_range(GameConfig.Player.PLAYER_1), Vector2i(14, 15), "player 1 deployment")
	assert_eq(GameConfig.deployment_row_range(GameConfig.Player.PLAYER_2), Vector2i(0, 1), "player 2 deployment")
	assert_eq(GameConfig.promotion_row(GameConfig.Player.PLAYER_1), 0, "player 1 promotion row")
	assert_eq(GameConfig.promotion_row(GameConfig.Player.PLAYER_2), 15, "player 2 promotion row")
	assert_true(GameConfig.is_in_home_half(GameConfig.Player.PLAYER_1, 8), "row 8 is player 1 home half")
	assert_false(GameConfig.is_in_home_half(GameConfig.Player.PLAYER_1, 7), "row 7 is not player 1 home half")
	assert_true(GameConfig.is_in_deployment_area(GameConfig.Player.PLAYER_2, 1), "row 1 is player 2 deployment")
	assert_false(GameConfig.is_in_deployment_area(GameConfig.Player.PLAYER_2, 2), "row 2 is not player 2 deployment")
	return true
