# ActionButtonPanel 使用指南

## 概述

ActionButtonPanel 是一个位于游戏场景右下角的像素风格操作按钮面板，提供快速访问游戏核心功能的入口。

## 功能特性

### 1. 快捷操作按钮
- **💬 对话 (D)**: 打开 Agent 对话系统
- **📊 监控 (M)**: 打开任务监控面板
- **🔧 工作 (W)**: 打开工作控制面板
- **⚙️ 设置 (S)**: 打开设置（待实现）

### 2. 展开/收起功能
- 点击标题栏的 **▼** 按钮可以收起面板
- 收起后显示为 **▶** 按钮，再次点击可展开
- 展开/收起动画流畅自然（0.3 秒）

### 3. 快捷键支持
- **D 键**: 打开对话框
- **M 键**: 打开监控面板
- **W 键**: 打开工作面板
- **Ctrl+S**: 打开设置
- **Tab 键**: 切换面板展开/收起状态

### 4. 响应式布局
- 自动定位在屏幕右下角
- 小屏幕下自动收起面板
- 窗口大小变化时保持正确位置

## 文件结构

```
microverse/
├── scene/ui/ActionButtonPanel.tscn    # 场景文件
└── script/ui/ActionButtonPanel.gd     # 脚本文件
```

## 集成方式

### 在场景中使用

```gdscript
# 1. 在场景树中添加 ActionButtonPanel 实例
[node name="ActionButtonPanel" parent="CanvasLayer" instance=ExtResource("action_button_panel")]

# 2. 在脚本中获取引用
@onready var action_panel = $CanvasLayer/ActionButtonPanel

# 3. 连接信号
func _ready():
    if action_panel:
        action_panel.dialog_requested.connect(_on_action_dialog_requested)
        action_panel.monitor_requested.connect(_on_action_monitor_requested)
        action_panel.work_requested.connect(_on_action_work_requested)
        action_panel.settings_requested.connect(_on_action_settings_requested)
        action_panel.panel_toggled.connect(_on_panel_toggled)

# 4. 实现信号处理函数
func _on_action_dialog_requested():
    # 打开对话框
    pass

func _on_action_monitor_requested():
    # 打开监控面板
    pass

func _on_action_work_requested():
    # 打开工作面板
    pass

func _on_action_settings_requested():
    # 打开设置
    pass

func _on_panel_toggled(is_expanded: bool):
    # 面板展开/收起状态变化
    print("面板展开状态: ", is_expanded)
```

## 信号说明

### 发出的信号

| 信号名称 | 参数 | 说明 |
|---------|------|------|
| `dialog_requested` | 无 | 用户点击"对话"按钮 |
| `monitor_requested` | 无 | 用户点击"监控"按钮 |
| `work_requested` | 无 | 用户点击"工作"按钮 |
| `settings_requested` | 无 | 用户点击"设置"按钮 |
| `panel_toggled` | `is_expanded: bool` | 面板展开/收起状态变化 |

## 自定义配置

### 修改动画速度

```gdscript
# 在 ActionButtonPanel.gd 中修改
var animation_duration: float = 0.5  # 默认 0.3 秒
```

### 修改面板位置

```gdscript
# 在 ActionButtonPanel.tscn 中修改 offset 属性
offset_left = -220.0   # 距离右边缘的距离
offset_top = -300.0    # 距离下边缘的距离
offset_right = -20.0   # 右边距
offset_bottom = -20.0  # 下边距
```

### 添加新按钮

```gdscript
# 在运行时动态添加按钮
func add_custom_button(text: String, icon: String, callback: Callable):
    var button = Button.new()
    button.text = "%s %s" % [icon, text]
    button.add_theme_font_override("font", pixel_font)
    button.add_theme_font_size_override("font_size", 12)
    button.pressed.connect(callback)
    button_container.add_child(button)
```

## 样式定制

### 使用像素字体

面板使用 `fusion-pixel-12px-proportional-zh_hans.otf` 像素字体，确保与游戏整体风格一致。

### 使用主题

面板使用 `MainTheme.tres` 主题，可以通过修改主题文件来统一调整所有 UI 元素的样式。

## 测试场景

在 `AgentRuntimeTest.tscn` 场景中已集成 ActionButtonPanel，可以直接运行测试：

1. 打开 Godot 编辑器
2. 运行 `AgentRuntimeTest.tscn` 场景（F6）
3. 观察右下角的操作按钮面板
4. 测试各个按钮和快捷键功能

## 已知问题

1. **设置功能未实现**: "设置"按钮目前只输出日志，实际功能待实现
2. **快捷键冲突**: 如果其他系统也使用 D/M/W/S 快捷键，可能会产生冲突

## 未来改进

1. **配置持久化**: 保存用户的展开/收起偏好
2. **主题切换**: 支持切换不同的像素风格主题
3. **动态按钮管理**: 支持运行时添加/移除按钮
4. **多语言支持**: 按钮文本支持国际化（i18n）
5. **音效反馈**: 添加按钮点击和展开/收起的音效

## 参考资料

- [Godot UI 系统文档](https://docs.godotengine.org/en/stable/tutorials/ui/index.html)
- [Godot Tween 动画](https://docs.godotengine.org/en/stable/classes/class_tween.html)
- [Godot 信号系统](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
