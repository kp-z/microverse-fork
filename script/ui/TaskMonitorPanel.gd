extends Control

## Task Monitor Panel: display task list and work logs
## Uses MicroverseAPIClient to fetch logs

signal task_selected(execution_id: int)
signal task_completed(execution_id: int, status: String)

@onready var main_panel = $MainPanel
@onready var title_label = $MainPanel/VBox/TitleLabel
@onready var task_list = $MainPanel/VBox/TaskList
@onready var log_container = $MainPanel/VBox/LogScroll/LogLabel
@onready var close_button = $MainPanel/VBox/CloseButton

var pixel_font = preload("res://asset/fonts/fusion-pixel-12px-proportional-zh_hans.otf")

var _tasks: Array = []  # [{execution_id, character, description, status}]
var _selected_execution_id: int = -1
var _log_timer: Timer = null
var _api_client = null
var _log_offset: int = 0

func _ready():
	_apply_pixel_font()
	_api_client = get_node_or_null("/root/MicroverseAPIClient")

	close_button.pressed.connect(_on_close_pressed)
	task_list.item_selected.connect(_on_task_item_selected)

	# log polling timer
	_log_timer = Timer.new()
	_log_timer.wait_time = 2.0
	_log_timer.timeout.connect(_poll_logs)
	add_child(_log_timer)

	print("[TaskMonitorPanel] ready")

func _apply_pixel_font():
	var font_size := 12
	for node in [title_label, close_button]:
		if node:
			node.add_theme_font_override("font", pixel_font)
			node.add_theme_font_size_override("font_size", font_size)
	if log_container:
		log_container.add_theme_font_override("font", pixel_font)
		log_container.add_theme_font_size_override("font_size", 10)
	if task_list:
		task_list.add_theme_font_override("font", pixel_font)
		task_list.add_theme_font_size_override("font_size", font_size)

# ===== Public API (called by AgentRuntimeTest) =====

func open_monitor():
	visible = true
	_refresh_task_list()
	if _selected_execution_id >= 0:
		_log_timer.start()

func close_monitor():
	visible = false
	_log_timer.stop()

func add_task(execution_id: int, character_name: String, description: String):
	var task := {
		"execution_id": execution_id,
		"character": character_name,
		"description": description,
		"status": "running"
	}
	_tasks.append(task)
	_refresh_task_list()

	# auto-select the new task
	_selected_execution_id = execution_id
	task_selected.emit(execution_id)
	_log_offset = 0
	log_container.text = ""
	_log_timer.start()

func update_task_status(execution_id: int, status: String):
	for task in _tasks:
		if task.execution_id == execution_id:
			task.status = status
			break
	_refresh_task_list()
	if status in ["succeeded", "failed", "cancelled"]:
		task_completed.emit(execution_id, status)

# ===== Internal =====

func _refresh_task_list():
	task_list.clear()
	for i in range(_tasks.size()):
		var task = _tasks[i]
		var icon := ">"
		match task.status:
			"running": icon = ">"
			"succeeded": icon = "+"
			"failed": icon = "X"
			"cancelled": icon = "-"
		var text := "%s [%s] %s" % [icon, task.character, task.description.left(30)]
		task_list.add_item(text)

func _on_task_item_selected(index: int):
	if index < 0 or index >= _tasks.size():
		return
	_selected_execution_id = _tasks[index].execution_id
	_log_offset = 0
	log_container.text = ""
	task_selected.emit(_selected_execution_id)
	_log_timer.start()

func _on_close_pressed():
	close_monitor()

func _poll_logs():
	if _api_client == null or _selected_execution_id < 0:
		return
	# find character name for the selected task
	var char_name := ""
	for task in _tasks:
		if task.execution_id == _selected_execution_id:
			char_name = task.character
			break
	if char_name == "":
		return

	var result = await _api_client.get_work_logs(char_name, _log_offset, 20)
	if result.success:
		var logs: Array = result.data.get("logs", [])
		if logs.size() > 0:
			for line in logs:
				log_container.text += str(line) + "\n"
			_log_offset += logs.size()
			# auto-scroll to bottom
			var scroll = log_container.get_parent()
			if scroll is ScrollContainer:
				await get_tree().process_frame
				scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
