extends TestCase


func test_labels_buttons_and_edits_scale_from_base() -> bool:
	var root := Control.new()
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 18)
	root.add_child(label)
	var button := Button.new()
	button.add_theme_font_size_override("font_size", 14)
	root.add_child(button)
	var edit := LineEdit.new()
	edit.add_theme_font_size_override("font_size", 16)
	root.add_child(edit)

	TextScale.apply(root, 1.5)
	assert_eq(label.get_theme_font_size("font_size"), 27, "label at 150%")
	assert_eq(button.get_theme_font_size("font_size"), 21, "button at 150%")
	assert_eq(edit.get_theme_font_size("font_size"), 24, "line edit at 150%")

	TextScale.apply(root, 1.25)
	assert_eq(label.get_theme_font_size("font_size"), 23, "label at 125% rounds")
	assert_eq(button.get_theme_font_size("font_size"), 18, "button at 125%")
	assert_eq(edit.get_theme_font_size("font_size"), 20, "line edit at 125%")

	TextScale.apply(root, 1.0)
	assert_eq(label.get_theme_font_size("font_size"), 18, "label returns to base")
	assert_eq(button.get_theme_font_size("font_size"), 14, "button returns to base")
	assert_eq(edit.get_theme_font_size("font_size"), 16, "line edit returns to base")
	root.free()
	return true


func test_apply_is_idempotent_and_tracks_new_children() -> bool:
	var root := VBoxContainer.new()
	var first := Label.new()
	first.add_theme_font_size_override("font_size", 12)
	root.add_child(first)
	TextScale.apply(root, 1.5)
	TextScale.apply(root, 1.5)
	assert_eq(first.get_theme_font_size("font_size"), 18, "repeated apply does not compound")
	var later := Label.new()
	later.add_theme_font_size_override("font_size", 20)
	root.add_child(later)
	TextScale.apply(root, 1.5)
	assert_eq(later.get_theme_font_size("font_size"), 30, "new children scale on the next pass")
	assert_eq(TextScale.base_font_size(later), 20, "base size is remembered")
	root.free()
	return true


func test_factor_is_clamped() -> bool:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 20)
	TextScale.apply(label, 3.0)
	assert_eq(label.get_theme_font_size("font_size"), 30, "factor is capped at 150%")
	label.free()
	return true
