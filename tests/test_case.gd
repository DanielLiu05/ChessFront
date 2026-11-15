class_name TestCase
extends RefCounted

var passed: int = 0
var failed: int = 0
var current_test: String = ""


func begin_test(test_name: String) -> void:
	current_test = test_name


func record_failure(message: String) -> void:
	failed += 1
	push_error("FAIL [%s] %s" % [current_test, message])


func assert_true(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		record_failure(message)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		passed += 1
	else:
		record_failure("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func assert_ne(actual: Variant, unexpected: Variant, message: String) -> void:
	if actual != unexpected:
		passed += 1
	else:
		record_failure("%s: did not expect %s" % [message, str(unexpected)])


func assert_null(value: Variant, message: String) -> void:
	assert_true(value == null, message)


func assert_not_null(value: Variant, message: String) -> void:
	assert_true(value != null, message)
