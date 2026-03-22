extends Node

## OfficeAgentBridge: connects ActionButtonPanel signals to Agent UI components
## Attach this as a child of the CanvasLayer that contains all Agent UI nodes.

@onready var action_panel = get_parent().get_node_or_null("ActionButtonPanel")
@onready var dialog_system = get_parent().get_node_or_null("AgentDialogSystem")
@onready var control_panel = get_parent().get_node_or_null("TaskControlPanel")
@onready var monitor_panel = get_parent().get_node_or_null("TaskMonitorPanel")

var _api_client = null

func _ready():
	_api_client = get_node_or_null("/root/MicroverseAPIClient")

	if action_panel:
		action_panel.dialog_requested.connect(_on_dialog)
		action_panel.monitor_requested.connect(_on_monitor)
		action_panel.work_requested.connect(_on_work)
		print("[OfficeAgentBridge] signals connected")
	else:
		print("[OfficeAgentBridge] ActionButtonPanel not found")

func _on_dialog():
	if not dialog_system:
		return
	var char_name := _get_selected_character_name()
	dialog_system.open_dialog(char_name)

func _on_monitor():
	if not monitor_panel:
		return
	monitor_panel.open_monitor()

func _on_work():
	if not control_panel:
		return
	control_panel.visible = true

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

	if handled:
		get_viewport().set_input_as_handled()
