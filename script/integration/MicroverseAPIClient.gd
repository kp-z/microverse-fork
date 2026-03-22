extends Node

## Open Adventure 后端 Microverse / AgentRuntime HTTP 客户端（Autoload）
## 对齐 FastAPI：`{base_url}{api_prefix}/microverse/*`

var base_url: String = "http://127.0.0.1:8000"
var api_prefix: String = "/api"
var _auth_token: String = ""

func _ready() -> void:
	call_deferred("_bind_settings_manager")


func _bind_settings_manager() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm and sm.has_signal("settings_changed"):
		if not sm.settings_changed.is_connected(_on_settings_changed):
			sm.settings_changed.connect(_on_settings_changed)
		if sm.has_method("get_settings"):
			_on_settings_changed(sm.get_settings())


func _on_settings_changed(new_settings: Dictionary) -> void:
	var u := str(new_settings.get("open_adventure_base_url", base_url)).strip_edges()
	base_url = u.rstrip("/")
	api_prefix = str(new_settings.get("open_adventure_api_prefix", api_prefix))
	if not api_prefix.begins_with("/"):
		api_prefix = "/" + api_prefix
	_auth_token = str(new_settings.get("open_adventure_auth_token", ""))


func refresh_config_from_settings() -> void:
	_bind_settings_manager()


## POST /microverse/chat
func post_microverse_chat(character_name: String, prompt: String, context: Variant = null) -> Dictionary:
	var payload := {
		"character_name": character_name,
		"prompt": prompt,
	}
	if context != null and typeof(context) == TYPE_DICTIONARY:
		payload["context"] = context
	return await _request_json(HTTPClient.METHOD_POST, "/microverse/chat", payload)


## POST /microverse/characters/{name}/work/start
func start_character_work(character_name: String, task_description: String, project_path: String = "") -> Dictionary:
	var body := {"task_description": task_description}
	if project_path.strip_edges() != "":
		body["project_path"] = project_path
	var path := "/microverse/characters/%s/work/start" % _encode_path_segment(character_name)
	return await _request_json(HTTPClient.METHOD_POST, path, body)


## POST /microverse/characters/{name}/work/stop
func stop_character_work(character_name: String) -> Dictionary:
	var path := "/microverse/characters/%s/work/stop" % _encode_path_segment(character_name)
	return await _request_json(HTTPClient.METHOD_POST, path, {})


## GET /microverse/characters/{name}/work/status
func get_work_status(character_name: String) -> Dictionary:
	var path := "/microverse/characters/%s/work/status" % _encode_path_segment(character_name)
	return await _request_json(HTTPClient.METHOD_GET, path, {})


## GET /microverse/characters/{name}/work/logs
func get_work_logs(character_name: String, offset: int = 0, limit: int = 50) -> Dictionary:
	var path := "/microverse/characters/%s/work/logs?offset=%d&limit=%d" % [
		_encode_path_segment(character_name), offset, limit
	]
	return await _request_json(HTTPClient.METHOD_GET, path, {})


## GET /microverse/agents — 获取项目级 Agent 列表
func get_microverse_agents() -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET, "/microverse/agents", {})


## GET /microverse/characters/{name} — 获取角色详情（含绑定 Agent）
func get_character_info(character_name: String) -> Dictionary:
	var path := "/microverse/characters/%s" % _encode_path_segment(character_name)
	return await _request_json(HTTPClient.METHOD_GET, path, {})


## PUT /microverse/characters/{name}/bind — 绑定角色到 Agent
func bind_character_agent(character_name: String, agent_id: int) -> Dictionary:
	var path := "/microverse/characters/%s/bind" % _encode_path_segment(character_name)
	return await _request_json(HTTPClient.METHOD_PUT, path, {"agent_id": agent_id})


## DELETE /microverse/characters/{name}/bind — 解绑角色
func unbind_character_agent(character_name: String) -> Dictionary:
	var path := "/microverse/characters/%s/bind" % _encode_path_segment(character_name)
	return await _request_json(HTTPClient.METHOD_DELETE, path, {})


func _encode_path_segment(s: String) -> String:
	return str(s).uri_encode()


func _request_json(method: int, path: String, body: Dictionary) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 15.0  # 防止后端无响应时协程永久挂起
	add_child(http)
	var url := base_url + api_prefix + path
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if _auth_token.strip_edges() != "":
		headers.append("Authorization: Bearer %s" % _auth_token)
	var body_str := ""
	if method != HTTPClient.METHOD_GET:
		body_str = JSON.stringify(body)
	var err := http.request(url, headers, method, body_str)
	if err != OK:
		http.queue_free()
		return {"success": false, "data": {}, "error": "request_init_failed: %s" % err}
	var args: Array = await http.request_completed
	http.queue_free()
	var result: int = args[0]
	var code: int = args[1]
	var body_bytes: PackedByteArray = args[3]
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"success": false, "data": {}, "error": "network_result: %s" % result}
	var text := body_bytes.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	var as_dict: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	if code >= 200 and code < 300:
		return {"success": true, "data": as_dict, "error": ""}
	var detail := text
	if as_dict.has("detail"):
		detail = str(as_dict.get("detail"))
	return {"success": false, "data": as_dict, "error": "http_%s: %s" % [code, detail]}
