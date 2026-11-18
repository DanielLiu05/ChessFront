extends TestCase


func test_ui_palette_matches_board_palette() -> bool:
	assert_eq(UiStyle.ink().to_html(false), "12100c", "ink")
	assert_eq(UiStyle.panel().to_html(false), "1c1712", "panel")
	assert_eq(UiStyle.parchment().to_html(false), PresentationConfig.PALETTE["light_body"].to_html(false), "parchment reuses unit ivory")
	assert_eq(UiStyle.gold().to_html(false), "f2b544", "gold reuses mine gold")
	assert_eq(UiStyle.color("brass").to_html(false), "b08a4f", "brass")
	assert_eq(UiStyle.color("ui_line").to_html(false), "4a3b28", "ui line")
	return true


func test_square_frames_and_selected_edge() -> bool:
	var style := UiStyle.button_style()
	assert_eq(style.corner_radius_top_left, 0, "no rounded corners")
	assert_eq(style.border_width_top, maxi(1, roundi(UiStyle.dp(1.0))), "hairline border")
	var selected := UiStyle.selected_button_style()
	assert_true(
		selected.border_width_left > selected.border_width_top,
		"selected rows carry a heavier left edge"
	)
	var primary := UiStyle.primary_button_style()
	assert_eq(primary.bg_color, UiStyle.gold(), "primary action uses brass gold")
	return true


func test_scrollbar_theme_is_procedural() -> bool:
	var theme := UiStyle.scrollbar_theme()
	assert_true(theme.has_stylebox("scroll", "VScrollBar"), "vertical track")
	assert_true(theme.has_icon("grabber", "VScrollBar"), "vertical grabber")
	assert_true(theme.has_icon("grabber_highlight", "VScrollBar"), "vertical hover grabber")
	assert_true(theme.has_icon("grabber", "HScrollBar"), "horizontal grabber")
	var grabber: Texture2D = theme.get_icon("grabber", "VScrollBar")
	assert_true(grabber != null and grabber.get_width() > 0, "grabber has pixels")
	var scroll := ScrollContainer.new()
	UiStyle.apply_scrollbar_theme(scroll)
	assert_true(scroll.theme == theme, "scroll containers receive the theme")
	scroll.free()
	return true


func test_table_texture_is_deterministic() -> bool:
	var first := UiStyle.grain_texture()
	var second := UiStyle.grain_texture()
	assert_eq(first.get_width(), 96, "grain width")
	assert_eq(first.get_height(), 96, "grain height")
	var first_pixel := first.get_image().get_pixel(10, 20)
	var second_pixel := second.get_image().get_pixel(10, 20)
	assert_true(first_pixel.is_equal_approx(second_pixel), "grain uses a fixed seed")
	var swatch := UiStyle.color_swatch(UiStyle.color("player_1"))
	assert_eq(swatch.get_width(), 24, "swatch size")
	return true
