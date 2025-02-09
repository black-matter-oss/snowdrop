class_name GlobalDebug
extends Node

const TIME_TEXT_COLOR: Color = Color.GREEN
const DEBUG_TEXT_COLOR: Color = Color.YELLOW

#static var _prev_measure_start: int = 0
#static var _prev_measure_end: int = 0

static var _measures: Dictionary[String, int] = {}

static func time_measure_start(group: String, key: String, begin: bool = true) -> void:
	if not OS.is_debug_build(): return

	if begin: DebugDraw2D.begin_text_group(group)
	_measures[group + key] = Time.get_ticks_usec()

static func time_measure_end(group: String, key: String, end: bool = true) -> void:
	if not OS.is_debug_build(): return
	if (group + key) not in _measures:
		print_debug("END WITHOUT START? " + (group + key))
		return

	DebugDraw2D.set_text(key + " (ms)", (Time.get_ticks_usec() - _measures[group + key]) / 1000.0, -1, TIME_TEXT_COLOR, 10.0)
	if end: DebugDraw2D.end_text_group()

	_measures.erase(group + key)

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

# debug keybinds
static var show_chunk_borders: bool = false

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build(): return

	if Input.is_action_just_pressed("debug_chunk_borders"):
		show_chunk_borders = not show_chunk_borders
