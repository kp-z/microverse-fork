extends Control

## Agent Dialog System: user input dialog for chatting with Agent characters
## Uses MicroverseAPIClient.post_microverse_chat()

signal response_received(response: String)
signal dialog_submitted(character_name: String, prompt: String)

@onready var main_panel = $MainPanel
@onready var title_label = $MainPanel/VBox/TitleLabel
@onready var history_scroll = $MainPanel/VBox/HistoryScroll
@onready var history_label = $MainPanel/VBox/HistoryScroll/HistoryLabel
@onready var input_field = $MainPanel/VBox/InputContainer/InputField
@onready var send_button = $MainPanel/VBox/InputContainer/SendButton
@onready var close_button = $MainPanel/VBox/CloseButton

var pixel_font = preload("res://asset/fonts/fusion-pixel-12px-proportional-zh_hans.otf")

var _current_character: String = ""
var _api_client = null
var _is_waiting: bool = false

func _ready():
	_apply_pixel_font()
	_api_client = get_node_or_null("/root/MicroverseAPIClient")

	send_button.pressed.connect(_on_send_pressed)
	close_button.pressed.connect(close_dialog)
	input_field.text_submitted.connect(func(_text): _on_send_pressed())

	print("[AgentDialogSystem] ready")

func _apply_pixel_font():
	var font_size := 12
	for node in [title_label, send_button, close_button]:
		if node:
			node.add_theme_font_override("font", pixel_font)
			node.add_theme_font_size_override("font_size", font_size)
	if history_label:
		history_label.add_theme_font_override("font", pixel_font)
		history_label.add_theme_font_size_override("font_size", 11)
	if input_field:
		input_field.add_theme_font_override("font", pixel_font)
		input_field.add_theme_font_size_override("font_size", font_size)

# ===== Public API (called by AgentRuntimeTest) =====

func open_dialog(character_name: String = ""):
	if character_name != "":
		_current_character = character_name
	title_label.text = "Chat: %s" % _current_character
	visible = true
	input_field.grab_focus()

func close_dialog():
	visible = false

# ===== Internal =====

func _on_send_pressed():
	var prompt: String = input_field.text.strip_edges()
	if prompt == "" or _is_waiting:
		return

	_append_message("You", prompt)
	input_field.text = ""
	dialog_submitted.emit(_current_character, prompt)

	_is_waiting = true
	send_button.disabled = true
	send_button.text = "..."

	if _api_client == null:
		_append_message("System", "MicroverseAPIClient not found")
		_reset_input()
		return

	# refresh config before calling
	if _api_client.has_method("refresh_config_from_settings"):
		_api_client.refresh_config_from_settings()

	var result = await _api_client.post_microverse_chat(_current_character, prompt, {})
	if result.get("success", false):
		var text := str(result.data.get("response", ""))
		_append_message(_current_character, text)
		response_received.emit(text)
	else:
		var err := str(result.get("error", "unknown"))
		_append_message("System", "Error: %s" % err)

	_reset_input()

func _reset_input():
	_is_waiting = false
	send_button.disabled = false
	send_button.text = "Send"

func _append_message(sender: String, text: String):
	history_label.text += "[%s]: %s\n" % [sender, text]
	# auto-scroll
	await get_tree().process_frame
	if history_scroll:
		history_scroll.scroll_vertical = history_scroll.get_v_scroll_bar().max_value
