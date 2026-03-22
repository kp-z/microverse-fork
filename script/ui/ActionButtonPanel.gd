extends Control

# 信号定义
signal dialog_requested
signal monitor_requested
signal work_requested
signal settings_requested
signal panel_toggled(is_expanded: bool)

# 节点引用
@onready var main_panel = $MainPanel
@onready var title_label = $MainPanel/VBoxContainer/HeaderContainer/TitleLabel
@onready var toggle_button = $MainPanel/VBoxContainer/HeaderContainer/ToggleButton
@onready var button_container = $MainPanel/VBoxContainer/ButtonContainer
@onready var dialog_button = $MainPanel/VBoxContainer/ButtonContainer/DialogButton
@onready var monitor_button = $MainPanel/VBoxContainer/ButtonContainer/MonitorButton
@onready var work_button = $MainPanel/VBoxContainer/ButtonContainer/WorkButton
@onready var settings_button = $MainPanel/VBoxContainer/ButtonContainer/SettingsButton

# 状态变量
var is_expanded: bool = true
var animation_duration: float = 0.3
var current_tween: Tween = null

# 像素字体
var pixel_font = preload("res://asset/fonts/fusion-pixel-12px-proportional-zh_hans.otf")

func _ready():
	# 应用像素字体
	_apply_pixel_font()

	# 连接按钮信号
	toggle_button.pressed.connect(_on_toggle_pressed)
	dialog_button.pressed.connect(_on_dialog_pressed)
	monitor_button.pressed.connect(_on_monitor_pressed)
	work_button.pressed.connect(_on_work_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	print("[ActionButtonPanel] 初始化完成")

func _apply_pixel_font():
	# 应用像素字体到所有文本元素
	var font_size = 12

	title_label.add_theme_font_override("font", pixel_font)
	title_label.add_theme_font_size_override("font_size", font_size)

	toggle_button.add_theme_font_override("font", pixel_font)
	toggle_button.add_theme_font_size_override("font_size", font_size)

	dialog_button.add_theme_font_override("font", pixel_font)
	dialog_button.add_theme_font_size_override("font_size", font_size)

	monitor_button.add_theme_font_override("font", pixel_font)
	monitor_button.add_theme_font_size_override("font_size", font_size)

	work_button.add_theme_font_override("font", pixel_font)
	work_button.add_theme_font_size_override("font_size", font_size)

	settings_button.add_theme_font_override("font", pixel_font)
	settings_button.add_theme_font_size_override("font_size", font_size)

func toggle_panel():
	is_expanded = !is_expanded
	_animate_toggle()
	panel_toggled.emit(is_expanded)

func _animate_toggle():
	# 停止之前的动画
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.set_ease(Tween.EASE_OUT)
	current_tween.set_trans(Tween.TRANS_CUBIC)

	if is_expanded:
		# 展开动画
		toggle_button.text = "▼"
		button_container.visible = true

		# 淡入 + 高度展开
		current_tween.tween_property(button_container, "modulate:a", 1.0, animation_duration)
		current_tween.parallel().tween_property(button_container, "custom_minimum_size:y", 200, animation_duration)
	else:
		# 收起动画
		toggle_button.text = "▶"

		# 淡出 + 高度收起
		current_tween.tween_property(button_container, "modulate:a", 0.0, animation_duration)
		current_tween.parallel().tween_property(button_container, "custom_minimum_size:y", 0, animation_duration)
		current_tween.tween_callback(func(): button_container.visible = false)

func _on_toggle_pressed():
	toggle_panel()

func _on_dialog_pressed():
	dialog_requested.emit()
	print("[ActionButtonPanel] 对话按钮被点击")

func _on_monitor_pressed():
	monitor_requested.emit()
	print("[ActionButtonPanel] 监控按钮被点击")

func _on_work_pressed():
	work_requested.emit()
	print("[ActionButtonPanel] 工作按钮被点击")

func _on_settings_pressed():
	settings_requested.emit()
	print("[ActionButtonPanel] 设置按钮被点击")

# 快捷键支持
func _input(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		# Skip hotkeys when a text field has focus (e.g. AgentDialogSystem input)
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner is LineEdit or focus_owner is TextEdit:
			return
		match event.keycode:
			KEY_1:
				_on_dialog_pressed()
			KEY_2:
				_on_monitor_pressed()
			KEY_3:
				_on_work_pressed()
			KEY_4:
				_on_settings_pressed()
			KEY_TAB:
				toggle_panel()

# 响应式布局
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_position()

func _update_position():
	# 确保面板始终在可见区域内
	var viewport_size = get_viewport_rect().size
	if viewport_size.x < 400 or viewport_size.y < 400:
		# 小屏幕：自动收起
		if is_expanded:
			toggle_panel()
