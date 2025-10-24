extends Control

# --- Variables ---
@export var chat_bubble_scene: PackedScene
var dialogue_resource: Resource
var current_line: DialogueLine
var is_waiting_for_input: bool = false
var current_chat_id: String = "" # Para saber qué chat está activo
var chat_progress: Dictionary = {} # Guarda un Array de DialogueLine por cada ID de chat


# --- Referencias a nodos ---
@onready var chat_history: VBoxContainer = %ChatHistory
@onready var options_container: VBoxContainer = %OptionsContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var avery_button: TextureButton = %avery
@onready var vanessa_button: TextureButton = %vanessa
@onready var send_button: Button = %SendButton

# --- Arranque ---
func _ready():
	modulate = Color(1, 1, 1, 1)
	# Conecta los botones a la función _on_chat_button_pressed
	avery_button.pressed.connect(_on_chat_button_pressed.bind("Avery"))
	vanessa_button.pressed.connect(_on_chat_button_pressed.bind("Vanessa"))
	# Conecta el botón "Enviar"
	send_button.pressed.connect(_on_send_button_pressed)

# --- Cambiar o iniciar un chat nuevo ---
func _on_chat_button_pressed(chat_id: String):
	print("Cambiando a chat:", chat_id)
	# Si hacemos clic en el mismo chat que ya está abierto, no hacemos nada
	if chat_id == current_chat_id:
		return
	current_chat_id = chat_id
	var dialogue_path = ""
	match chat_id:
		"Avery":
			dialogue_path = "res://dialogue/mi_chat_2.dialogue"
		"Vanessa":
			dialogue_path = "res://dialogue/mi_chat.dialogue"
		_:
			print("Error: chat_id desconocido:", chat_id)
			return

	if ResourceLoader.exists(dialogue_path):
		dialogue_resource = load(dialogue_path)
		# Si ya tenemos historial para este chat se muestra
		if chat_progress.has(chat_id):
			_rebuild_chat_history(chat_id)
		else:
			# Si es nuevo, empieza desde "inicio"
			chat_progress[chat_id] = [] # Crea una lista vacía para el historial
			start_dialogue("inicio") # Llama a la función que inicia desde cero
	else:
		print("Error: No se encontró el archivo de diálogo:", dialogue_path)

# --- NUEVA FUNCIÓN: Reconstruir historial visual ---
func _rebuild_chat_history(chat_id: String):
	print("Reconstruyendo historial para:", chat_id)

	# 1. Limpia el área de chat actual (burbujas y botones)
	for child in chat_history.get_children():
		# Descomenta la protección del Spacer si lo está usando
		# if child.name != "Spacer":
			child.queue_free()
	for child in options_container.get_children():
		child.queue_free()

	# 2. Obtiene el historial guardado (Array de DialogueLine)
	var history: Array = chat_progress.get(chat_id, [])

	# 3. Vuelve a crear CADA burbuja del historial
	for line in history:
		# Verifica que 'line' sea del tipo correcto antes de usar sus propiedades
		if line is DialogueLine and not line.character.is_empty():
			var bubble = chat_bubble_scene.instantiate()
			chat_history.add_child(bubble)
			bubble.get_node("NamePanel/NameLabel").text = line.character
			bubble.get_node("BubblePanel/DialogueLabel").text = line.text
			style_bubble(bubble, line.character)

	# 4. Obtiene la ÚLTIMA línea del historial para saber dónde continuar
	if not history.is_empty():
		current_line = history.back() # La última línea que se mostró
		# Verifica que current_line sea válido
		if current_line is DialogueLine:
			# Si la última línea tenía opciones, muestrala de nuevo
			if current_line.responses.size() > 0:
				is_waiting_for_input = true
				for i in range(current_line.responses.size()):
					var option = current_line.responses[i]
					var button = Button.new()
					button.text = option.text
					button.pressed.connect(on_option_button_pressed.bind(i))
					options_container.add_child(button)
			else:
				is_waiting_for_input = true
		else:
			print("Error: Última línea del historial inválida.")
			start_dialogue("inicio") # Error, reinicia
	else:
		# Si el historial estaba vacío (error?), empieza de cero
		start_dialogue("inicio")
	# 5. Scroll al fondo
	call_deferred("_scroll_to_bottom")

# Esta función inicia un chat desde cero VISUALMENTE
func start_dialogue(title_or_id: String):
	# Limpia burbujas anteriores, PERO protege al Spacer si se activa
	for child in chat_history.get_children():
		# Descomenta la protección del Spacer si se usa
		# if child.name != "Spacer":
			child.queue_free()

	# Limpia botones de opción anteriores
	for child in options_container.get_children():
		child.queue_free()

	# Pide la PRIMERA línea y empieza el proceso
	current_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, title_or_id)
	_process_dialogue_line() # Esto mostrará la primera línea Y la guardará en el historial


# --- Procesar y mostrar la línea actual ---
func _process_dialogue_line():
	if current_line == null:
		print("Diálogo terminado.")
		is_waiting_for_input = false
		# Borra el progreso de este chat al terminar
		if chat_progress.has(current_chat_id):
			chat_progress.erase(current_chat_id)
			print("Borrado progreso para [", current_chat_id, "] porque terminó.")
		return

	# --- GUARDAR EN HISTORIAL ---
	# Añade la línea actual al historial del chat activo
	if chat_progress.has(current_chat_id):
		chat_progress[current_chat_id].append(current_line)
	# --- FIN GUARDAR ---

	# 1. Muestra la burbuja de texto (si hay personaje)
	if not current_line.character.is_empty():
		var bubble = chat_bubble_scene.instantiate()
		chat_history.add_child(bubble)
		bubble.get_node("NamePanel/NameLabel").text = current_line.character
		bubble.get_node("BubblePanel/DialogueLabel").text = current_line.text
		style_bubble(bubble, current_line.character)
		call_deferred("_scroll_to_bottom") # Scroll al fondo

	# 2. Muestra los botones de opción (si los hay)
	if current_line.responses.size() > 0:
		for i in range(current_line.responses.size()):
			var option = current_line.responses[i]
			var button = Button.new()
			button.text = option.text
			button.pressed.connect(on_option_button_pressed.bind(i))
			options_container.add_child(button)

	# 3. PAUSA: Espera input del jugador
	is_waiting_for_input = true


# --- Scroll Helper ---
func _scroll_to_bottom():
	await get_tree().process_frame
	if scroll_container.get_v_scroll_bar():
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value


# --- Manejar clic en "Enviar" ---
func _on_send_button_pressed():
	# Solo avanza si estamos esperando input Y NO hay botones de opción visibles
	if not is_waiting_for_input or options_container.get_child_count() > 0:
		return

	is_waiting_for_input = false
	current_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, current_line.next_id)
	_process_dialogue_line()


# --- Manejar Clic en Botón de Opción ---
func on_option_button_pressed(index: int):
	if not is_waiting_for_input:
		return

	is_waiting_for_input = false
	for child in options_container.get_children():
		child.queue_free()

	var next_id = current_line.responses[index].next_id
	current_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, next_id)
	_process_dialogue_line()


# --- Función de Estilo ---
func style_bubble(bubble: VBoxContainer, character: String):
	var name_label = bubble.get_node("NamePanel/NameLabel")

	if character == "Player":
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END
		bubble.alignment = BoxContainer.ALIGNMENT_END
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		bubble.alignment = BoxContainer.ALIGNMENT_BEGIN
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
