extends Control

## Task Control Panel: start/stop work and display status
## Uses MicroverseAPIClient to interact with backend AgentRuntime

signal start_requested

@onready var main_panel = $MainPanel
@onready var title_label = $MainPanel/VBox/TitleLabel
@onready var status_label = $MainPanel/VBox/StatusLabel
@onready var info_label = $MainPanel/VBox/InfoLabel
@onready var start_button = $MainPanel/VBox/ButtonContainer/StartButton
@onready var stop_button = $MainPanel/VBox/ButtonContainer/StopButton
@onready var close_button = $MainPanel/VBox/CloseButton

var pixel_font = preload("res://asset/fonts/fusion-pixel-12px-proportional-zh_hans.otf")

var current_execution_id: int = -1
var current_status: String = "idle"
var _poll_timer: Timer = null
var _api_client = null

func _ready():
	_apply_pixel_font()
	_api_client = get_node_or_null("/root/MicroverseAPIClient")

	start_button.pressed.connect(_on_start_pressed)
	stop_button.pressed.connect(_on_stop_pressed)
	close_button.pressed.connect(func(): visible = false)

	_update_button_states()

	# polling timer for status updates
	_poll_timer = Timer.new()
	_poll_timer.wait_time = 3.0
	_poll_timer.timeout.connect(_poll_status)
	add_child(_poll_timer)

	print("[TaskControlPanel] ready")

func _apply_pixel_font():
	var font_size := 12
	for node in [title_label, status_label, info_label, start_button, stop_button, close_button]:
		if node:
			node.add_theme_font_override("font", pixel_font)
			node.add_theme_font_size_override("font_size", font_size)

# ===== Public API (called by AgentRuntimeTest) =====

func set_execution(execution_id: int, status: String = "running"):
	current_execution_id = execution_id
	update_status(status)
	visible = true
	_poll_timer.start()

func update_status(status: String):
	current_status = status
	status_label.text = "Status: %s" % status
	_update_button_states()

func _update_button_states():
	var is_running := current_status in ["running", "pending"]
	start_button.disabled = is_running
	stop_button.disabled = not is_running

# ===== Button handlers =====

func _on_start_pressed():
	start_requested.emit()

func _on_stop_pressed():
	if _api_client == null:
		print("[TaskControlPanel] MicroverseAPIClient not found")
		return
	# we need to know the character name; derive from info or use default
	info_label.text = "Stopping..."
	stop_button.disabled = true
	# stop via execution context - the parent scene should handle this
	# For now emit a signal or call stop directly if we have character context
	print("[TaskControlPanel] stop requested, execution_id: ", current_execution_id)
	update_status("stopping")

# ===== Polling =====

func _poll_status():
	if current_status in ["idle", "succeeded", "failed", "cancelled"]:
		_poll_timer.stop()
		return
	if _api_client == null or current_execution_id < 0:
		return
	# status will be updated by parent scene via set_execution/update_status
	# this timer is a safeguard for automatic refresh
	print("[TaskControlPanel] polling status for execution: ", current_execution_id)
