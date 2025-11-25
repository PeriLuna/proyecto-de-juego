extends Control

# --- SEÑALES ---
signal thought_requested(thought_title)
signal background_change_requested(bg_code)

# --- Variables ---
@export var chat_bubble_scene: PackedScene
@export var npc_reply_delay: float = 0.5
var dialogue_resource: Resource
var current_line: DialogueLine
var is_waiting_for_input: bool = false
var current_chat_id: String = ""
var chat_progress: Dictionary = {} 
var is_paused_by_thought: bool = false 

# --- Referencias ---
@onready var chat_history: VBoxContainer = %ChatHistory
@onready var options_container: VBoxContainer = %OptionsContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var avery_button: TextureButton = %avery
@onready var vanessa_button: TextureButton = %vanessa
@onready var send_button: Button = %SendButton
@onready var text_input: LineEdit = %TextInput

func _ready():
	modulate = Color(1, 1, 1, 1)
	avery_button.pressed.connect(_on_chat_button_pressed.bind("Avery"))
	vanessa_button.pressed.connect(_on_chat_button_pressed.bind("Vanessa"))
	send_button.pressed.connect(_on_send_button_pressed)
	send_button.disabled = true
	text_input.text = ""
	text_input.editable = false

func start_specific_chat(chat_id: String, resource: Resource, start_title: String):
	print("ChatUI recibiendo orden de iniciar chat:", chat_id)
	current_chat_id = chat_id
	dialogue_resource = resource 
	
	if chat_progress.has(chat_id):
		_rebuild_chat_history(chat_id)
	else:
		chat_progress[chat_id] = []
		start_dialogue(start_title)

func _on_chat_button_pressed(chat_id: String):
	if is_paused_by_thought: return 
	if chat_id == current_chat_id: return
	current_chat_id = chat_id
	var dialogue_path = ""
	match chat_id:
		"Avery": dialogue_path = "res://dialogue/mi_chat_2.dialogue"
		"Vanessa": dialogue_path = "res://dialogue/mi_chat.dialogue"
		_: return

	if ResourceLoader.exists(dialogue_path):
		dialogue_resource = load(dialogue_path)
		if chat_progress.has(chat_id):
			_rebuild_chat_history(chat_id)
		else:
			chat_progress[chat_id] = []
			start_dialogue("inicio")

func _rebuild_chat_history(chat_id: String):
	_clear_chat_area()
	var history: Array = chat_progress.get(chat_id, [])
	for line in history:
		if line is DialogueLine and not line.character.is_empty():
			if line.character == "Narrador": continue 
			var bubble = chat_bubble_scene.instantiate()
			chat_history.add_child(bubble)
			bubble.get_node("NamePanel/NameLabel").text = line.character
			bubble.get_node("BubblePanel/DialogueLabel").text = line.text
			bubble.get_node("BubblePanel/DialogueLabel").visible_characters = -1
			style_bubble(bubble, line.character)
	
	if not history.is_empty():
		current_line = history.back()
		if current_line is DialogueLine:
			if current_line.responses.size() > 0:
				_display_options(current_line.responses)
				is_waiting_for_input = true
				send_button.disabled = true
				text_input.text = ""
			else:
				is_waiting_for_input = (current_line.character == "Player")
				send_button.disabled = not is_waiting_for_input
				text_input.text = current_line.text if is_waiting_for_input else ""
		else:
			start_dialogue("inicio")
	else:
		start_dialogue("inicio")
	call_deferred("_scroll_to_bottom")

func start_dialogue(title_or_id: String):
	_clear_chat_area()
	text_input.text = ""
	is_waiting_for_input = false
	_request_next_line(title_or_id)

func _clear_chat_area():
	for child in chat_history.get_children():
		if child.name != "Spacer": child.queue_free()
	for child in options_container.get_children():
		child.queue_free()

func _process_dialogue_line():
	if is_paused_by_thought: return
	
	if current_line == null or current_line.character != "Player":
		text_input.text = ""

	if current_line == null:
		print("Diálogo terminado.")
		is_waiting_for_input = false
		send_button.disabled = true
		if chat_progress.has(current_chat_id): chat_progress.erase(current_chat_id)
		return

	if chat_progress.has(current_chat_id):
		if chat_progress[current_chat_id].is_empty() or chat_progress[current_chat_id].back() != current_line:
			chat_progress[current_chat_id].append(current_line)

	# --- LÓGICA DEL NARRADOR ---
	if current_line.character == "Narrador":
		if current_line.text == "[GAME_OVER_GLITCH]":
			print("Iniciando secuencia final...")
			get_tree().change_scene_to_file("res://escenas/final_scene.tscn")
			return
			
		elif current_line.text.begins_with("[BG_"):
			print("Chat solicitó cambio de fondo: ", current_line.text)
			emit_signal("background_change_requested", current_line.text)
			_request_next_line(current_line.next_id)
			return
		
		else:
			print("Chat detectó un pensamiento: ", current_line.text)
			emit_signal("thought_requested", current_line.text)
			return 
	# --- FIN LÓGICA NARRADOR ---

	var is_player = false
	if not current_line.character.is_empty():
		is_player = (current_line.character == "Player")
		var bubble = chat_bubble_scene.instantiate()
		chat_history.add_child(bubble)
		style_bubble(bubble, current_line.character)

		if is_player:
			text_input.text = current_line.text
			if bubble.has_method("start_typing"): bubble.start_typing(current_line.character, current_line.text)
			else: 
				bubble.get_node("NamePanel/NameLabel").text = current_line.character
				bubble.get_node("BubblePanel/DialogueLabel").text = current_line.text
		else:
			if bubble.has_method("show_instantly"): bubble.show_instantly(current_line.character, current_line.text)
			else: 
				bubble.get_node("NamePanel/NameLabel").text = current_line.character
				bubble.get_node("BubblePanel/DialogueLabel").text = current_line.text

		call_deferred("_scroll_to_bottom")

	if current_line.responses.size() > 0:
		_display_options(current_line.responses)
		is_waiting_for_input = true
		send_button.disabled = true
		text_input.text = ""
	elif is_player:
		is_waiting_for_input = true
		send_button.disabled = false
	else:
		is_waiting_for_input = false
		send_button.disabled = true
		_request_next_line(current_line.next_id)

func _request_next_line(next_id: String):
	if is_paused_by_thought or is_waiting_for_input: return
	send_button.disabled = true

	var next_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, next_id)
	if next_line == null:
		current_line = null
		_process_dialogue_line()
		return

	var is_next_line_npc = (next_line.character != "Player" and not next_line.character.is_empty())
	if is_next_line_npc:
		await get_tree().create_timer(npc_reply_delay).timeout

	current_line = next_line
	_process_dialogue_line()

func _display_options(responses: Array):
	for i in range(responses.size()):
		var option = responses[i]
		if option is DialogueResponse:
			var button = Button.new()
			button.text = option.text
			button.pressed.connect(on_option_button_pressed.bind(i))
			options_container.add_child(button)

func _scroll_to_bottom():
	await get_tree().process_frame
	if scroll_container.get_v_scroll_bar():
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _on_send_button_pressed():
	if is_paused_by_thought: return
	if not is_waiting_for_input or options_container.get_child_count() > 0: return
	is_waiting_for_input = false
	send_button.disabled = true
	text_input.text = ""
	_request_next_line(current_line.next_id)

func on_option_button_pressed(index: int):
	if is_paused_by_thought: return
	if not is_waiting_for_input: return
	is_waiting_for_input = false
	send_button.disabled = true
	text_input.text = ""
	for child in options_container.get_children(): child.queue_free()
	if current_line is DialogueLine and index >= 0 and index < current_line.responses.size():
		var next_id = current_line.responses[index].next_id
		_request_next_line(next_id)

func style_bubble(bubble: VBoxContainer, character: String):
	var name_label = bubble.get_node_or_null("NamePanel/NameLabel")
	if not name_label: return
	if character == "Player":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END
		bubble.alignment = BoxContainer.ALIGNMENT_END
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		bubble.alignment = BoxContainer.ALIGNMENT_BEGIN
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func pause_for_thought():
	is_paused_by_thought = true
	send_button.disabled = true

func resume_after_thought():
	is_paused_by_thought = false
	if current_line != null and current_line.character == "Narrador":
		_request_next_line(current_line.next_id)
	else:
		if is_waiting_for_input and options_container.get_child_count() == 0 and current_line != null and current_line.character == "Player":
			send_button.disabled = false
