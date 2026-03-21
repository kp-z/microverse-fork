extends Node2D

## 对话气泡：使用 speech.png 作为与 Agent/角色对话时的背景，并锚定在角色头顶上方

var target_node: Node2D = null
var text_label: Label
var background: NinePatchRect
var tween: Tween
var is_target_on_right: bool = false

## 从角色根节点 global_position 向上多少像素视为「头顶」参考线（32x64 行走图约 48~56，可按角色调整）
@export var head_offset_from_origin_px: float = 52.0
## 气泡底边与头顶参考线之间的空隙
@export var gap_above_head_px: float = 6.0
## speech.png 为 64x64 九宫格时，边距需与贴图圆角/尾巴留白一致，可在编辑器中微调
@export var patch_margin: int = 10

func _ready():
	# 步骤 1：显示层级高于场景内大部分节点
	z_index = 100
	
	# 步骤 2：气泡背景（与 Agent 对话统一使用 speech.png）
	background = NinePatchRect.new()
	background.texture = preload("res://asset/ui/speech.png")
	background.patch_margin_left = patch_margin
	background.patch_margin_top = patch_margin
	background.patch_margin_right = patch_margin
	background.patch_margin_bottom = patch_margin
	add_child(background)
	
	# 创建文本标签
	text_label = Label.new()
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(100, 40)
	# 设置自定义字体
	var custom_font = preload("res://asset/fonts/fusion-pixel-12px-proportional-zh_hans.otf")
	text_label.add_theme_font_override("font", custom_font)
	text_label.add_theme_font_size_override("font_size", 12) # 设置字体大小
	text_label.add_theme_color_override("font_color", Color(0, 0, 0, 1)) # 设置字体颜色为黑色
	background.add_child(text_label)
	
	# 初始时隐藏
	hide()

# 显示对话内容
func show_dialog(text: String, duration: float = 5.0, target_on_right: bool = false):
	text_label.text = text
	is_target_on_right = target_on_right
	
	# 调整背景大小以适应文本
	await get_tree().process_frame
	var text_size = text_label.size
	background.size = text_size + Vector2(20, 20)
	text_label.position = Vector2(10, 10)
	
	# 显示气泡
	show()
	
	# 创建消失动画
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_callback(hide)

# 更新位置：每帧跟随目标，锚定在头顶上方（而非脚底 global_position）
func _process(_delta):
	if target_node and visible:
		# 步骤 1：头顶参考点 = 角色原点向上偏移（CharacterBody2D 原点通常在脚附近）
		var head_anchor = target_node.global_position + Vector2(0, -head_offset_from_origin_px)
		# 步骤 2：水平居中——气泡中心对齐角色中心
		var bubble_x = head_anchor.x - background.size.x / 2.0
		# 步骤 3：垂直——气泡整体在头顶参考线上方，留出 gap_above_head_px
		var bubble_y = head_anchor.y - gap_above_head_px - background.size.y
		global_position = Vector2(bubble_x, bubble_y)
