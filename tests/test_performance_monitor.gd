extends TestCase


func test_frame_time_summary() -> bool:
	var monitor := PhasePerformanceMonitor.new()
	monitor.start("")
	for _index in 99:
		monitor.record_frame(1.0 / 60.0)
	monitor.record_frame(0.1)
	var summary := monitor.stop()
	assert_eq(int(summary["frames"]), 100, "all frames are recorded")
	assert_true(float(summary["average_fps"]) > 50.0, "average fps is computed")
	assert_true(float(summary["average_fps"]) < 60.0, "average includes the slow frame")
	assert_true(
		is_equal_approx(float(summary["one_percent_low"]), 10.0),
		"one-percent low uses the worst frame"
	)
	assert_true(
		is_equal_approx(float(summary["max_frame_ms"]), 100.0),
		"maximum frame time is reported in milliseconds"
	)
	monitor.free()
	return true


func test_empty_summary() -> bool:
	var monitor := PhasePerformanceMonitor.new()
	monitor.start("")
	var summary := monitor.stop()
	assert_eq(int(summary["frames"]), 0, "empty run has no frames")
	assert_eq(float(summary["average_fps"]), 0.0, "empty average fps is zero")
	assert_eq(float(summary["one_percent_low"]), 0.0, "empty one-percent low is zero")
	monitor.free()
	return true
