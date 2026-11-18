extends TestCase


func test_landscape_override() -> bool:
	WebViewport.set_test_landscape(true)
	assert_true(WebViewport.is_landscape(), "landscape override is true")
	WebViewport.set_test_landscape(false)
	assert_false(WebViewport.is_landscape(), "landscape override is false")
	WebViewport.clear_test_landscape()
	return true


func test_orientation_pause_resolution() -> bool:
	assert_true(
		WebViewport.resolve_orientation_pause(true, true, true),
		"mobile web landscape pauses"
	)
	assert_false(
		WebViewport.resolve_orientation_pause(true, true, false),
		"mobile web portrait does not pause"
	)
	assert_false(
		WebViewport.resolve_orientation_pause(true, false, true),
		"PC web landscape does not pause"
	)
	assert_false(
		WebViewport.resolve_orientation_pause(false, true, true),
		"native landscape does not use the web pause"
	)
	return true
