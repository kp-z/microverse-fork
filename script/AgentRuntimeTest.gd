extends Node2D

# Godot Agent Runtime 集成测试场景
# 演示对话系统、任务监控和控制面板的使用

@onready var dialog_system = $CanvasLayer/AgentDialogSystem
@onready var monitor_panel = $CanvasLayer/TaskMonitorPanel
@onready var control_panel = $CanvasLayer/TaskControlPanel
@onready var action_panel = $CanvasLayer/ActionButtonPanel
@onready var test_ui = $CanvasLayer/TestUI

var api_client
var current_character: String = "Alice"
var current_execution_id: int = -1

func _ready():
	# 获取 API 客户端
	api_client = get_node("/root/MicroverseAPIClient")

	# 连接信号
	_connect_signals()

	# 初始化测试 UI
	_setup_test_ui()

	print("[AgentRuntimeTest] 测试场景已加载")

func _connect_signals():
	"""连接所有信号"""
	# 对话系统
	if dialog_system:
		dialog_system.response_received.connect(_on_dialog_response)

	# 监控面板
	if monitor_panel:
		monitor_panel.task_selected.connect(_on_task_selected)
		monitor_panel.task_completed.connect(_on_task_completed)

	# 控制面板
	if control_panel:
		control_panel.start_requested.connect(_on_start_task)

	# 操作按钮面板
	if action_panel:
		action_panel.dialog_requested.connect(_on_action_dialog_requested)
		action_panel.monitor_requested.connect(_on_action_monitor_requested)
		action_panel.work_requested.connect(_on_action_work_requested)
		action_panel.settings_requested.connect(_on_action_settings_requested)

func _setup_test_ui():
	"""设置测试 UI 按钮"""
	if not test_ui:
		return

	var open_dialog_btn = test_ui.get_node("PanelContainer/VBoxContainer/OpenDialogButton")
	var open_monitor_btn = test_ui.get_node("PanelContainer/VBoxContainer/OpenMonitorButton")
	var start_work_btn = test_ui.get_node("PanelContainer/VBoxContainer/StartWorkButton")

	if open_dialog_btn:
		open_dialog_btn.pressed.connect(_on_open_dialog_pressed)

	if open_monitor_btn:
		open_monitor_btn.pressed.connect(_on_open_monitor_pressed)

	if start_work_btn:
		start_work_btn.pressed.connect(_on_start_work_pressed)

# ===== 测试按钮事件 =====

func _on_open_dialog_pressed():
	"""打开对话框"""
	print("[AgentRuntimeTest] 打开对话框: ", current_character)
	if dialog_system:
		dialog_system.open_dialog(current_character)

func _on_open_monitor_pressed():
	"""打开监控面板"""
	print("[AgentRuntimeTest] 打开监控面板")
	if monitor_panel:
		monitor_panel.open_monitor()

func _on_start_work_pressed():
	"""启动测试任务"""
	print("[AgentRuntimeTest] 启动测试任务")
	await _start_test_work()

# ===== 核心功能 =====

func _start_test_work():
	"""启动测试工作"""
	var task_description = "测试任务: 实现一个简单的登录功能"
	var project_path = "/tmp/test_project"

	print("[AgentRuntimeTest] 启动工作: ", current_character, " - ", task_description)

	var result = await api_client.start_character_work(
		current_character,
		task_description,
		project_path
	)

	if result.success:
		current_execution_id = result.data.get("execution_id", -1)
		print("[AgentRuntimeTest] 任务已启动, execution_id: ", current_execution_id)

		# 添加到监控面板
		if monitor_panel:
			monitor_panel.add_task(current_execution_id, current_character, task_description)

		# 设置控制面板
		if control_panel:
			control_panel.set_execution(current_execution_id, "running")

	else:
		print("[AgentRuntimeTest] 启动任务失败: ", result.error)

# ===== 信号处理 =====

func _on_dialog_response(response: String):
	"""处理对话响应"""
	print("[AgentRuntimeTest] Agent 回复: ", response)

func _on_task_selected(execution_id: int):
	"""任务被选中"""
	print("[AgentRuntimeTest] 任务被选中: ", execution_id)
	current_execution_id = execution_id

	if control_panel:
		control_panel.set_execution(execution_id, "running")

func _on_task_completed(execution_id: int, status: String):
	"""任务完成"""
	print("[AgentRuntimeTest] 任务完成: ", execution_id, " 状态: ", status)

	if control_panel and current_execution_id == execution_id:
		control_panel.update_status(status)

func _on_start_task():
	"""启动任务（从控制面板）"""
	print("[AgentRuntimeTest] 从控制面板启动任务")
	await _start_test_work()

# ===== ActionButtonPanel 信号处理 =====

func _on_action_dialog_requested():
	"""从操作面板打开对话框"""
	print("[AgentRuntimeTest] 从操作面板打开对话框")
	if dialog_system:
		dialog_system.open_dialog(current_character)

func _on_action_monitor_requested():
	"""从操作面板打开监控面板"""
	print("[AgentRuntimeTest] 从操作面板打开监控面板")
	if monitor_panel:
		monitor_panel.open_monitor()

func _on_action_work_requested():
	"""从操作面板打开工作面板"""
	print("[AgentRuntimeTest] 从操作面板打开工作面板")
	if control_panel:
		control_panel.visible = true

func _on_action_settings_requested():
	"""从操作面板打开设置"""
	print("[AgentRuntimeTest] 设置功能待实现")
	# TODO: 实现设置功能

# ===== 键盘快捷键 =====

func _input(event):
	"""处理键盘输入"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				# ESC 关闭所有面板
				if dialog_system and dialog_system.visible:
					dialog_system.close_dialog()
				if monitor_panel and monitor_panel.visible:
					monitor_panel.close_monitor()
			# 注意: D/M/W/S 快捷键已由 ActionButtonPanel 处理
