extends Control

## AgentBindPanel: UI for binding Microverse characters to project-level Agents
## Opened via ActionButtonPanel "设置(4)" → OfficeAgentBridge

signal agent_bound(character_name: String, agent_id: int, agent_name: String)
signal agent_unbound(character_name: String)

@onready var main_panel = $MainPanel
@onready var title_label = $MainPanel/VBox/TitleLabel
@onready var current_label = $MainPanel/VBox/CurrentLabel
@onready var agent_list = $MainPanel/VBox/AgentScroll/AgentList
@onready var status_label = $MainPanel/VBox/StatusLabel
@onready var bind_button = $MainPanel/VBox/ButtonContainer/BindButton
@onready var unbind_button = $MainPanel/VBox/ButtonContainer/UnbindButton
@onready var refresh_button = $MainPanel/VBox/ButtonContainer/RefreshButton
@onready var close_button = $MainPanel/VBox/CloseButton

var pixel_font = preload("res://asset/fonts/fusion-pixel-12px-proportional-zh_hans.otf")
var speech_tex = preload("res://asset/ui/speech.png")

var _current_character: String = ""
var _agents: Array = []
var _bound_agent_id: int = -1
var _api_client = null
var _is_loading: bool = false

func _ready():
	_apply_pixel_font()
	_apply_speech_bg()
	_api_client = get_node_or_null("/root/MicroverseAPIClient")

	bind_button.pressed.connect(_on_bind_pressed)
	unbind_button.pressed.connect(_on_unbind_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	close_button.pressed.connect(close_panel)
	agent_list.item_selected.connect(_on_agent_selected)
	_update_button_states()

	print("[AgentBindPanel] ready")

func _apply_pixel_font():
	var font_size := 12
	for node in [title_label, current_label, status_label, bind_button,
				unbind_button, refresh_button, close_button]:
		if node:
			node.add_theme_font_override("font", pixel_font)
			node.add_theme_font_size_override("font_size", font_size)
	if agent_list:
		agent_list.add_theme_font_override("font", pixel_font)
		agent_list.add_theme_font_size_override("font_size", 11)

func _apply_speech_bg():
	var sb := StyleBoxTexture.new()
	sb.texture = speech_tex
	sb.texture_margin_left = 10
	sb.texture_margin_top = 10
	sb.texture_margin_right = 10
	sb.texture_margin_bottom = 10
	sb.content_margin_left = 12
	sb.content_margin_top = 12
	sb.content_margin_right = 12
	sb.content_margin_bottom = 12
	main_panel.add_theme_stylebox_override("panel", sb)

# ===== Public API =====

func open_panel(character_name: String):
	_current_character = character_name
	title_label.text = "Agent: %s" % character_name
	visible = true
	_fetch_data()

func close_panel():
	visible = false

# ===== Data Loading =====

func _fetch_data():
	if _api_client == null:
		status_label.text = "APIClient not found"
		return

	_set_loading(true)
	status_label.text = "Loading..."

	# Fetch agent list
	var agents_result = await _api_client.get_microverse_agents()
	if agents_result.get("success", false):
		_agents = agents_result.data.get("agents", [])
		if typeof(_agents) != TYPE_ARRAY:
			_agents = []
	else:
		status_label.text = "Error: %s" % str(agents_result.get("error", "unknown"))
		_set_loading(false)
		return

	# Fetch character binding info
	var char_result = await _api_client.get_character_info(_current_character)
	if char_result.get("success", false):
		var raw_agent_id = char_result.data.get("agent_id", null)
		_bound_agent_id = int(raw_agent_id) if raw_agent_id != null else -1
		var agent_info = char_result.data.get("agent", null)
		if agent_info and typeof(agent_info) == TYPE_DICTIONARY:
			current_label.text = "当前: %s" % str(agent_info.get("name", ""))
		else:
			_bound_agent_id = -1
			current_label.text = "当前: 未绑定"
	else:
		_bound_agent_id = -1
		current_label.text = "当前: 未绑定"

	_populate_agent_list()
	status_label.text = "%d agents" % _agents.size()
	_set_loading(false)
	_update_button_states()

func _populate_agent_list():
	agent_list.clear()
	for agent in _agents:
		var agent_name: String = str(agent.get("name", "unknown"))
		var desc: String = str(agent.get("description", ""))
		if desc.length() > 40:
			desc = desc.left(40) + "..."

		var label: String = agent_name
		if desc != "":
			label += " - %s" % desc

		# Mark currently bound agent
		if int(agent.get("id", -1)) == _bound_agent_id:
			label = "> " + label

		agent_list.add_item(label)

# ===== Actions =====

func _on_bind_pressed():
	var selected = agent_list.get_selected_items()
	if selected.size() == 0 or _is_loading:
		return
	var idx: int = selected[0]
	if idx < 0 or idx >= _agents.size():
		return
	var agent = _agents[idx]
	var agent_id: int = int(agent.get("id", -1))
	if agent_id < 0:
		return

	_set_loading(true)
	status_label.text = "Binding..."

	var result = await _api_client.bind_character_agent(_current_character, agent_id)
	if result.get("success", false):
		var agent_name: String = str(agent.get("name", ""))
		_bound_agent_id = agent_id
		current_label.text = "当前: %s" % agent_name
		status_label.text = "Bound!"
		agent_bound.emit(_current_character, agent_id, agent_name)
		_populate_agent_list()
	else:
		status_label.text = "Error: %s" % str(result.get("error", "unknown"))

	_set_loading(false)
	_update_button_states()

func _on_unbind_pressed():
	if _is_loading or _bound_agent_id < 0:
		return

	_set_loading(true)
	status_label.text = "Unbinding..."

	var result = await _api_client.unbind_character_agent(_current_character)
	if result.get("success", false):
		_bound_agent_id = -1
		current_label.text = "当前: 未绑定"
		status_label.text = "Unbound"
		agent_unbound.emit(_current_character)
		_populate_agent_list()
	else:
		status_label.text = "Error: %s" % str(result.get("error", "unknown"))

	_set_loading(false)
	_update_button_states()

func _on_refresh_pressed():
	_fetch_data()

func _on_agent_selected(_idx: int):
	_update_button_states()

# ===== Helpers =====

func _set_loading(loading: bool):
	_is_loading = loading
	bind_button.disabled = loading
	unbind_button.disabled = loading
	refresh_button.disabled = loading

func _update_button_states():
	var has_selection: bool = agent_list.get_selected_items().size() > 0
	bind_button.disabled = _is_loading or not has_selection
	unbind_button.disabled = _is_loading or _bound_agent_id < 0
