extends Node

# 单例实例
static var instance = null

# API URLs现在通过APIConfig统一管理

# 当前设置（从SettingsManager获取）
var current_settings = {}

# 获取单例实例
static func get_instance() -> APIManager:
	if instance == null:
		instance = Engine.get_singleton("APIManager")
		if instance == null:
			print("[APIManager] 创建新的APIManager实例")
			instance = APIManager.new()
	return instance

func _enter_tree():
	# 设置单例实例
	if instance == null:
		instance = self
	
	add_to_group("api_manager")

# 在_ready中连接设置管理器
func _ready():
	# 连接设置变化信号
	SettingsManager.settings_changed.connect(_on_settings_changed)
	# 获取当前设置
	current_settings = SettingsManager.get_settings()
	print("[APIManager] 已连接设置管理器，当前设置 - API类型：", current_settings.api_type, "，模型：", current_settings.model)

# 设置变化回调
func _on_settings_changed(new_settings: Dictionary):
	current_settings = new_settings.duplicate()
	print("[APIManager] 设置已更新 - API类型：", current_settings.api_type, "，模型：", current_settings.model)

# 生成对话（支持角色独立AI设置）
# 返回值：open_adventure 模式返回 Dictionary（包含 text/success 字段），本地模式返回 HTTPRequest
func generate_dialog(prompt: String, character_name: String = "") -> Variant:
	# 确保节点已经初始化
	if not is_inside_tree():
		push_error("APIManager is not properly initialized!")
		return null

	# 等待三帧以确保完全初始化
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# 使用 Open Adventure 后端 Microverse Chat（与本地 Ollama 等互斥）
	if str(current_settings.get("dialog_provider", "local")) == "open_adventure":
		print("[APIManager] 对话来源：Open Adventure /microverse/chat，角色：", character_name)
		return await _call_open_adventure_chat(prompt, character_name)

	# 创建新的HTTPRequest节点，不清理之前的节点
	var http_request = HTTPRequest.new()
	# 为每个请求设置唯一名称
	http_request.name = "HTTPRequest_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
	add_child(http_request)

	# 设置请求完成后自动清理
	http_request.request_completed.connect(func(result, response_code, headers, body):
		# 延迟清理，确保回调函数执行完毕
		get_tree().create_timer(1.0).timeout.connect(func():
			if http_request and is_instance_valid(http_request):
				remove_child(http_request)
				http_request.queue_free()
		)
	)

	# 获取角色对应的AI设置（本地/第三方 LLM）
	var ai_settings = current_settings
	if character_name != "":
		ai_settings = SettingsManager.get_character_ai_settings(character_name)
		print("[APIManager] 为角色 ", character_name, " 使用AI设置 - API类型：", ai_settings.api_type, "，模型：", ai_settings.model)
	else:
		print("[APIManager] 使用默认AI设置 - API类型：", ai_settings.api_type, "，模型：", ai_settings.model)
	
	# 使用APIConfig构建请求
	var headers = APIConfig.build_headers(ai_settings.api_type, ai_settings.api_key)
	var data = JSON.stringify(APIConfig.build_request_data(ai_settings.api_type, ai_settings.model, prompt))
	var url = APIConfig.get_url(ai_settings.api_type, ai_settings.model)
	
	print("[APIManager] 发送请求到 ", ai_settings.api_type, " API，模型：", ai_settings.model)
	
	print("[APIManager] 请求URL：", url)
	print("[APIManager] 创建HTTPRequest节点：", http_request.name)
	http_request.request(url, headers, HTTPClient.METHOD_POST, data)
	return http_request


## 调用 MicroverseAPIClient，直接返回结果 Dictionary（不再通过 HTTPRequest 信号中转）
func _call_open_adventure_chat(prompt: String, character_name: String) -> Dictionary:
	var who := character_name.strip_edges() if character_name.strip_edges() != "" else "Unknown"
	var client := get_node_or_null("/root/MicroverseAPIClient")
	if client == null:
		push_error("[APIManager] MicroverseAPIClient 未注册，无法使用 open_adventure 对话模式")
		return {"success": false, "text": "", "error": "MicroverseAPIClient not found"}
	if client.has_method("refresh_config_from_settings"):
		client.refresh_config_from_settings()
	var res: Dictionary = await client.post_microverse_chat(who, prompt, {})
	if res.get("success", false):
		var text := str(res.data.get("response", ""))
		return {"success": true, "text": text, "error": ""}
	else:
		return {"success": false, "text": "", "error": str(res.get("error", "unknown"))}

# 生成AI决策
func generate_decision(prompt: String, character_name: String = "") -> HTTPRequest:
	return await generate_dialog(prompt, character_name)
