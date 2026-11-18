class_name UiStyle
extends RefCounted

const OVERLINE_SIZE_DP: float = 11.0
const BODY_SIZE_DP: float = 14.0

static var _scroll_theme: Theme = null


static func color(key: String) -> Color:
	return PresentationConfig.PALETTE.get(key, Color.MAGENTA)


static func ink() -> Color:
	return color("ink")


static func panel() -> Color:
	return color("panel")


static func parchment() -> Color:
	return color("light_body")


static func muted() -> Color:
	return color("ui_muted")


static func gold() -> Color:
	return color("mine_gold")


static func dp(value: float) -> float:
	return MobileMetrics.dp_to_ui(value)


static func button_style(
	fill: Color = Color(-1, -1, -1, -1),
	border: Color = Color(-1, -1, -1, -1)
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color("panel_raised") if fill.a < 0.0 else fill
	style.border_color = color("ui_line") if border.a < 0.0 else border
	style.set_border_width_all(maxi(1, roundi(dp(1.0))))
	style.set_corner_radius_all(0)
	style.content_margin_left = dp(14.0)
	style.content_margin_right = dp(14.0)
	style.content_margin_top = dp(9.0)
	style.content_margin_bottom = dp(9.0)
	return style


static func selected_button_style(accent: Color = Color(-1, -1, -1, -1)) -> StyleBoxFlat:
	var accent_color := gold() if accent.a < 0.0 else accent
	var style := button_style(color("panel_raised").lightened(0.06), accent_color)
	style.border_width_left = maxi(3, roundi(dp(3.0)))
	return style


static func quiet_button_style() -> StyleBoxFlat:
	var style := button_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0))
	style.content_margin_top = dp(7.0)
	style.content_margin_bottom = dp(7.0)
	return style


static func primary_button_style() -> StyleBoxFlat:
	var style := button_style(gold(), gold().darkened(0.18))
	return style


static func focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = gold()
	style.set_border_width_all(maxi(1, roundi(dp(1.0))))
	style.set_corner_radius_all(0)
	return style


static func style_button(
	button: Button,
	fill: Color = Color(-1, -1, -1, -1),
	border: Color = Color(-1, -1, -1, -1)
) -> void:
	button.add_theme_stylebox_override("normal", button_style(fill, border))
	button.add_theme_stylebox_override(
		"hover", button_style(
			color("panel_raised").lightened(0.08),
			color("brass").darkened(0.12) if border.a < 0.0 else border.lightened(0.12)
		)
	)
	button.add_theme_stylebox_override(
		"pressed", button_style(color("panel_raised").darkened(0.12), border)
	)
	button.add_theme_stylebox_override("focus", focus_style())
	button.add_theme_color_override("font_color", parchment())
	button.add_theme_color_override("font_hover_color", parchment())
	button.add_theme_color_override("font_pressed_color", parchment())
	button.add_theme_color_override("font_focus_color", parchment())
	button.add_theme_color_override("font_disabled_color", muted().darkened(0.25))


static func style_quiet_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", quiet_button_style())
	button.add_theme_stylebox_override("hover", button_style(color("panel_raised").lightened(0.04), Color(0, 0, 0, 0)))
	button.add_theme_stylebox_override("pressed", button_style(color("panel_raised").darkened(0.08), Color(0, 0, 0, 0)))
	button.add_theme_stylebox_override("focus", focus_style())
	button.add_theme_color_override("font_color", muted())
	button.add_theme_color_override("font_hover_color", parchment())
	button.add_theme_color_override("font_pressed_color", parchment())
	button.add_theme_color_override("font_focus_color", parchment())
	button.add_theme_color_override("font_disabled_color", muted().darkened(0.3))


static func style_primary_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", primary_button_style())
	button.add_theme_stylebox_override(
		"hover", button_style(gold().lightened(0.08), gold().darkened(0.1))
	)
	button.add_theme_stylebox_override(
		"pressed", button_style(gold().darkened(0.12), gold().darkened(0.25))
	)
	button.add_theme_stylebox_override("focus", focus_style())
	button.add_theme_color_override("font_color", ink())
	button.add_theme_color_override("font_hover_color", ink())
	button.add_theme_color_override("font_pressed_color", ink())
	button.add_theme_color_override("font_focus_color", ink())
	button.add_theme_color_override("font_disabled_color", muted())


static func style_panel(
	panel: PanelContainer,
	fill: Color = Color(-1, -1, -1, -1),
	padding_dp: float = -1.0
) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = panel() if fill.a < 0.0 else fill
	style.border_color = color("ui_line")
	style.set_border_width_all(maxi(1, roundi(dp(1.0))))
	style.border_width_top = maxi(2, roundi(dp(2.0)))
	style.set_corner_radius_all(0)
	if padding_dp >= 0.0:
		var padding := dp(padding_dp)
		style.content_margin_left = padding
		style.content_margin_right = padding
		style.content_margin_top = padding
		style.content_margin_bottom = padding
	panel.add_theme_stylebox_override("panel", style)


static func make_rule(rule_color: Color = Color(-1, -1, -1, -1), height_dp: float = 1.0) -> ColorRect:
	var rule := ColorRect.new()
	rule.color = color("ui_line") if rule_color.a < 0.0 else rule_color
	rule.custom_minimum_size.y = maxf(1.0, dp(height_dp))
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


static func make_overline(text: String, size_dp: float = OVERLINE_SIZE_DP) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(dp(8.0)))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := ColorRect.new()
	mark.color = gold()
	mark.custom_minimum_size = Vector2(dp(4.0), dp(4.0))
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mark)
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override("font_size", roundi(dp(size_dp)))
	label.add_theme_color_override("font_color", gold())
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	var rule := make_rule(color("ui_line_soft"))
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rule)
	return row


static func make_display_title(text: String, size_dp: float) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(dp(size_dp)))
	label.add_theme_color_override("font_color", parchment())
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	label.add_theme_constant_override("shadow_offset_y", maxi(1, roundi(dp(1.0))))
	return label


static func make_caption(text: String, size_dp: float = 12.0) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(dp(size_dp)))
	label.add_theme_color_override("font_color", muted())
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func add_table_background(parent: Control) -> void:
	var background := ColorRect.new()
	background.name = "TableBackground"
	background.color = ink()
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(background)

	var lamp := TextureRect.new()
	lamp.name = "TableLamp"
	lamp.texture = lamp_gradient()
	lamp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lamp.stretch_mode = TextureRect.STRETCH_SCALE
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lamp)

	var grain := TextureRect.new()
	grain.name = "TableGrain"
	grain.texture = grain_texture()
	grain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	grain.stretch_mode = TextureRect.STRETCH_TILE
	grain.modulate = Color(1, 1, 1, 0.05)
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(grain)


static func lamp_gradient() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.62, 0.48, 0.28, 0.16),
		Color(0.35, 0.27, 0.16, 0.06),
		Color(0, 0, 0, 0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.18)
	texture.fill_to = Vector2(0.5, 0.85)
	texture.width = 256
	texture.height = 256
	return texture


static func grain_texture() -> ImageTexture:
	var size := 96
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5EED
	for y in size:
		for x in size:
			var value := rng.randf_range(0.0, 1.0)
			image.set_pixel(x, y, Color(value, value * 0.92, value * 0.8, 0.55))
	return ImageTexture.create_from_image(image)


static func color_swatch(swatch: Color) -> ImageTexture:
	var size := 24
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in size:
		for x in size:
			var edge := x == 0 or y == 0 or x == size - 1 or y == size - 1
			image.set_pixel(x, y, swatch.darkened(0.35) if edge else swatch)
	return ImageTexture.create_from_image(image)


static func apply_scrollbar_theme(root: Node) -> void:
	if root == null:
		return
	for node: Node in root.find_children("*", "ScrollContainer", true, false):
		var scroll := node as ScrollContainer
		if scroll != null:
			scroll.theme = scrollbar_theme()
	if root is ScrollContainer:
		(root as ScrollContainer).theme = scrollbar_theme()


static func scrollbar_theme() -> Theme:
	if _scroll_theme != null:
		return _scroll_theme
	var theme := Theme.new()
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.32)
	track.content_margin_left = dp(2.0)
	track.content_margin_right = dp(2.0)
	track.content_margin_top = dp(2.0)
	track.content_margin_bottom = dp(2.0)
	theme.set_stylebox("scroll", "VScrollBar", track)
	theme.set_stylebox("scroll_focus", "VScrollBar", track)
	theme.set_stylebox("scroll", "HScrollBar", track)
	theme.set_stylebox("scroll_focus", "HScrollBar", track)
	theme.set_icon("grabber", "VScrollBar", _grabber_texture(false))
	theme.set_icon("grabber_highlight", "VScrollBar", _grabber_texture(true))
	theme.set_icon("grabber_pressed", "VScrollBar", _grabber_texture(true, 0.18))
	theme.set_icon("increment", "VScrollBar", _arrow_texture(false))
	theme.set_icon("decrement", "VScrollBar", _arrow_texture(true))
	theme.set_icon("grabber", "HScrollBar", _grabber_texture(false, 0.0, true))
	theme.set_icon("grabber_highlight", "HScrollBar", _grabber_texture(true, 0.0, true))
	theme.set_icon("grabber_pressed", "HScrollBar", _grabber_texture(true, 0.18, true))
	theme.set_icon("increment", "HScrollBar", _arrow_texture(false, true))
	theme.set_icon("decrement", "HScrollBar", _arrow_texture(true, true))
	_scroll_theme = theme
	return theme


static func _grabber_texture(
	highlight: bool,
	brighten: float = 0.0,
	horizontal: bool = false
) -> ImageTexture:
	var width := 24 if horizontal else 8
	var height := 8 if horizontal else 24
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var grabber := color("brass")
	if highlight:
		grabber = grabber.lightened(0.16)
	grabber = grabber.lightened(brighten)
	for y in height:
		for x in width:
			var vertical_inset := y < 2 or y >= height - 2
			var horizontal_inset := x < 2 or x >= width - 2
			if horizontal and vertical_inset:
				continue
			if not horizontal and horizontal_inset:
				continue
			image.set_pixel(x, y, grabber)
	return ImageTexture.create_from_image(image)


static func _arrow_texture(decrement: bool, horizontal: bool = false) -> ImageTexture:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var shade := color("ui_muted")
	for step in 4:
		for spread in range(0, step + 1):
			var point := Vector2i(3 - step + spread if decrement else 4 + step - spread, 3 + step)
			if horizontal:
				point = Vector2i(3 + step, 3 - step + spread if decrement else 4 + step - spread)
			image.set_pixel(point.x, point.y, shade)
	return ImageTexture.create_from_image(image)
