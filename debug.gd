class_name GlobalDebug
extends Node

const TIME_TEXT_COLOR: Color = Color.GREEN
const DEBUG_TEXT_COLOR: Color = Color.YELLOW

static var _prev_measure_start: int = 0
static var _prev_measure_end: int = 0

static func time_measure_start(group: String) -> void:
	if not OS.is_debug_build(): return

	DebugDraw2D.begin_text_group(group)
	_prev_measure_start = Time.get_ticks_usec()

static func time_measure_end(key: String) -> void:
	if not OS.is_debug_build(): return

	_prev_measure_end = Time.get_ticks_usec()

	DebugDraw2D.set_text(key + " (ms)", (_prev_measure_end - _prev_measure_start) / 1000.0, -1, TIME_TEXT_COLOR, 10.0)
	DebugDraw2D.end_text_group()

func _process(delta: float) -> void:
	if not OS.is_debug_build(): return

	DebugDraw2D.begin_text_group("DEBUG/MEMORY", -10, DEBUG_TEXT_COLOR)
	#DebugDraw2D.set_text("memory info")

	var mem_info := OS.get_memory_info()
	DebugDraw2D.set_text("physical (MiB)", mem_info["physical"] / 1024 / 1024)
	DebugDraw2D.set_text("available (MiB)", mem_info["available"] / 1024 / 1024)
	DebugDraw2D.set_text("stack (MiB)", mem_info["stack"] / 1024 / 1024)
	DebugDraw2D.set_text("used (MiB)", snapped(OS.get_static_memory_usage() / 1024.0 / 1024.0, 0.001))

	DebugDraw2D.end_text_group()
	DebugDraw2D.end_text_group()
