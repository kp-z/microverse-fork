extends Node

## OfficeAgentBridge: connects ActionButtonPanel signals to Agent UI components
## Attach this as a child of the CanvasLayer that contains all Agent UI nodes.

@onready var action_panel = get_parent().get_node_or_null("ActionButtonPanel")
@onready var dialog_system = get_parent().get_node_or_null("AgentDialogSystem")
@onready var control_panel = get_parent().get_node_or_null("TaskControlPanel")
@onready var monitor_panel = get_parent().get_node_or_null("TaskMonitorPanel")
@onready var agent_bind_panel = get_parent().get_node_or_null("AgentBindPanel")

var _api_client = null

# Track bound agent names per character (populated by AgentBindPanel signals)
var _character_agent_names: Dictionary = {}

func _ready():
	_api_client = get_node_or_null("/root/MicroverseAPIClient")

	if action_panel:
		action_panel.dialog_requested.connect(_on_dialog)
		action_panel.monitor_requested.connect(_on_monitor)
		action_panel.work_requested.connect(_on_work)
		action_panel.settings_requested.connect(_on_settings)
		print("[OfficeAgentBridge] signals connected")
	else:
		print("[OfficeAgentBridge] ActionButtonPanel not found")

	if agent_bind_panel:
		agent_bind_panel.agent_bound.connect(_on_agent_bound)
		agent_bind_panel.agent_unbound.connect(_on_agent_unbound)

func _on_dialog():
	if not dialog_system:
		return
	var char_name := _get_selected_character_name()
	var agent_name: String = _character_agent_names.get(char_name, "")
	dialog_system.open_dialog(char_name, agent_name)

func _on_monitor():
	if not monitor_panel:
		return
	monitor_panel.open_monitor()

func _on_work():
	if not control_panel:
		return
	control_panel.visible = true

func _on_settings():
	if not agent_bind_panel:
		return
	var char_name := _get_selected_character_name()
	agent_bind_panel.open_panel(char_name)

func _on_agent_bound(character_name: String, _agent_id: int, agent_name: String):
	_character_agent_names[character_name] = agent_name
	print("[OfficeAgentBridge] %s bound to %s" % [character_name, agent_name])

func _on_agent_unbound(character_name: String):
	_character_agent_names.erase(character_name)
	print("[OfficeAgentBridge] %s unbound" % character_name)

func _get_selected_character_name() -> String:
	var cm = get_node_or_null("/root/CharacterManager")
	if cm and cm.current_character:
		return str(cm.current_character.name)
	return "Alice"

# ESC: close Agent panels first, before DialogManager opens settings
func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	if event.keycode != KEY_ESCAPE:
		return

	# close visible Agent panels and consume the event
	var handled := false
	if dialog_system and dialog_system.visible:
		dialog_system.close_dialog()
		handled = true
	if monitor_panel and monitor_panel.visible:
		monitor_panel.close_monitor()
		handled = true
	if control_panel and control_panel.visible:
		control_panel.visible = false
		handled = true
	if agent_bind_panel and agent_bind_panel.visible:
		agent_bind_panel.close_panel()
		handled = true

	if handled:
		get_viewport().set_input_as_handled()
