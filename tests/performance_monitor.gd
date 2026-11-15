class_name PhasePerformanceMonitor
extends Node

const DEFAULT_OUTPUT: String = "user://phase7_performance.csv"

var output_path: String = DEFAULT_OUTPUT
var frame_times: Array[float] = []
var samples: Array[Dictionary] = []
var running: bool = false

var _elapsed: float = 0.0
var _sample_elapsed: float = 0.0
var _file: FileAccess
var _below_streak: int = 0
var _max_below_seconds: int = 0


func start(path: String = DEFAULT_OUTPUT) -> void:
	frame_times.clear()
	samples.clear()
	_elapsed = 0.0
	_sample_elapsed = 0.0
	_below_streak = 0
	_max_below_seconds = 0
	output_path = path
	running = true
	_file = null
	if not output_path.is_empty():
		_file = FileAccess.open(output_path, FileAccess.WRITE)
		if _file != null:
			_file.store_line("elapsed_s,fps,frame_ms,draw_calls,memory_mb")


func stop() -> Dictionary:
	running = false
	if _file != null:
		_file.flush()
		_file.close()
		_file = null
	return summary()


func record_frame(delta: float) -> void:
	if not running or delta <= 0.0:
		return
	frame_times.append(delta)
	_elapsed += delta
	_sample_elapsed += delta
	if _sample_elapsed >= 1.0:
		_sample_elapsed = 0.0
		_record_sample()


func summary() -> Dictionary:
	var total_time := 0.0
	for frame_time: float in frame_times:
		total_time += frame_time
	var average_fps := 0.0
	if total_time > 0.0:
		average_fps = float(frame_times.size()) / total_time
	var one_percent_low := 0.0
	var max_frame_ms := 0.0
	if not frame_times.is_empty():
		var sorted: Array = frame_times.duplicate()
		sorted.sort()
		var index := clampi(int(floor(sorted.size() * 0.99)), 0, sorted.size() - 1)
		var worst_frame: float = float(sorted[index])
		if worst_frame > 0.0:
			one_percent_low = 1.0 / worst_frame
		max_frame_ms = float(sorted[sorted.size() - 1]) * 1000.0
	var draw_total := 0.0
	var memory_total := 0.0
	for sample: Dictionary in samples:
		draw_total += float(sample["draw_calls"])
		memory_total += float(sample["memory_mb"])
	var sample_count := samples.size()
	return {
		"frames": frame_times.size(),
		"samples": sample_count,
		"elapsed_s": total_time,
		"average_fps": average_fps,
		"one_percent_low": one_percent_low,
		"max_frame_ms": max_frame_ms,
		"draw_calls_avg": draw_total / sample_count if sample_count > 0 else 0.0,
		"memory_mb_avg": memory_total / sample_count if sample_count > 0 else 0.0,
		"max_below_50_seconds": _max_below_seconds,
	}


func _process(delta: float) -> void:
	record_frame(delta)


func _record_sample() -> void:
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms := (1000.0 / fps) if fps > 0.0 else 0.0
	var draw_calls := int(
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	)
	var memory_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	samples.append(
		{
			"elapsed": _elapsed,
			"fps": fps,
			"frame_ms": frame_ms,
			"draw_calls": draw_calls,
			"memory_mb": memory_mb,
		}
	)
	if fps < 50.0:
		_below_streak += 1
		_max_below_seconds = maxi(_max_below_seconds, _below_streak)
	else:
		_below_streak = 0
	if _file != null:
		_file.store_line(
			"%.2f,%.1f,%.2f,%d,%.1f"
			% [_elapsed, fps, frame_ms, draw_calls, memory_mb]
		)
