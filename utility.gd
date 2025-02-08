class_name GlobalUtility

static var _schedules: Dictionary[String, Array] = {}

static func schedule_later(group: String, callable: Callable) -> void:
	if group not in _schedules:
		_schedules[group] = []
	
	_schedules[group].append(callable)

static func run_schedules(group: String) -> void:
	if group not in _schedules: return

	for x: Callable in _schedules[group]:
		x.call()
