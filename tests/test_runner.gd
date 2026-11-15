extends SceneTree

const TEST_DIRECTORY: String = "res://tests"
const TEST_PREFIX: String = "test_"
const EXCLUDED_FILES: Array[String] = ["test_runner.gd", "test_case.gd"]

var _assertions_passed: int = 0
var _failures: int = 0


func _initialize() -> void:
	var test_files := _discover_test_files()
	if test_files.is_empty():
		push_error("No test files found in %s" % TEST_DIRECTORY)
		_failures += 1
	for path in test_files:
		_run_test_file(path)
	print("Results: %d assertions passed, %d failures" % [_assertions_passed, _failures])
	quit(1 if _failures > 0 else 0)


func _discover_test_files() -> Array[String]:
	var test_files: Array[String] = []
	for file_name: String in DirAccess.get_files_at(TEST_DIRECTORY):
		if file_name in EXCLUDED_FILES:
			continue
		if file_name.begins_with(TEST_PREFIX) and file_name.ends_with(".gd"):
			test_files.append("%s/%s" % [TEST_DIRECTORY, file_name])
	test_files.sort()
	return test_files


func _run_test_file(path: String) -> void:
	var script: Script = load(path) as Script
	if script == null:
		push_error("FAIL %s: could not load script" % path)
		_failures += 1
		return
	var test_names := _test_method_names(script)
	if test_names.is_empty():
		push_error("FAIL %s: no test methods" % path)
		_failures += 1
		return
	for test_name in test_names:
		_run_test(script, path, test_name)


func _run_test(script: Script, path: String, test_name: String) -> void:
	var instance: Variant = script.new()
	if not (instance is TestCase):
		push_error("FAIL %s: does not extend TestCase" % path)
		_failures += 1
		return
	var test_case: TestCase = instance
	test_case.begin_test(test_name)
	var result: Variant = test_case.call(test_name)
	if result != true:
		test_case.record_failure("did not return true (runtime error or early exit?)")
	_assertions_passed += test_case.passed
	_failures += test_case.failed
	if test_case.failed == 0 and result == true:
		print("PASS %s::%s" % [path, test_name])
	else:
		print("FAIL %s::%s" % [path, test_name])


func _test_method_names(script: Script) -> Array[String]:
	var names: Array[String] = []
	for method_info in script.get_script_method_list():
		var method_name := String(method_info.name)
		if method_name.begins_with(TEST_PREFIX):
			names.append(method_name)
	names.sort()
	return names
