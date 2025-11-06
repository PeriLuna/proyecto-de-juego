extends Control

# --- Referencias a Nodos (¡Verifica los Nombres Únicos!) ---
@onready var ares_window = %AresWindow
@onready var download_bar = %DownloadBar
@onready var message_sound = %MessageSound
@onready var world_bubble = %CanvasLayer/WorldDialogueBubble # Ruta al globo

# --- Recursos ---
# ¡ASEGÚRATE DE QUE LA RUTA "dialoge" (con "e") SEA CORRECTA!
var cinematic_resource = preload("res://dialogue/cinematic_dialogue.dialogue") 
var current_line: DialogueLine
var download_tween: Tween # Variable para guardar la animación

func _ready():
	# Asegúrate de que todo esté oculto al empezar
	ares_window.hide()
	download_bar.hide()
	
	# Inicia la cinemática
	_start_cinematic()

# --- Detectar "Enter" para avanzar ---
func _input(event):
	# Si se presiona "Enter" Y el globo está visible
	if world_bubble.is_showing and event.is_action_pressed("ui_accept"):
		world_bubble.hide_bubble() # Oculta el globo actual
		_advance_dialogue() # Pide la siguiente línea

# --- Control de Flujo ---

func _start_cinematic():
	# Pide la primera línea
	_request_next_line("inicio_cinematica")

func _advance_dialogue():
	# Pide la siguiente línea basada en el ID de la línea actual
	if current_line != null:
		_request_next_line(current_line.next_id)

func _request_next_line(id: String):
	# Pide la línea al DialogueManager
	current_line = await DialogueManager.get_next_dialogue_line(cinematic_resource, id)
	# Llama a la función que procesa la línea
	_process_current_line()

# --- Lógica Principal ---

func _process_current_line():
	# Si no hay más líneas (llegó a => END), termina la cinemática
	if current_line == null:
		_end_cinematic()
		return

	# Comprueba quién "habla"
	if current_line.character == "Player":
		# Si es el jugador, muestra el pensamiento en el globo.
		world_bubble.show_line(current_line.text)
	
	elif current_line.character == "Narrador":
		# Si es el Narrador, ejecuta una acción
		# ¡IMPORTANTE! 'await' pausa la cinemática aquí
		await _handle_action(current_line.text)
		
		# Como el globo no se mostró, avanzamos automáticamente
		_advance_dialogue()

# --- Función para Acciones (¡LÓGICA SIMPLIFICADA!) ---
func _handle_action(action: String):
	match action:
		
		"[ACCION_MOSTRAR_ARES]":
			print("Acción: Mostrando Ares e INICIANDO descarga...")
			ares_window.show()
			download_bar.value = 0 # Asegura que la barra esté vacía
			download_bar.show()
			
			if download_tween and download_tween.is_running():
				download_tween.kill()
			
			download_tween = create_tween()
			
			# ¡NUEVO! Pon aquí el tiempo que quieras que dure la descarga
			var duracion_descarga = 8.0 # <-- 8 segundos
			
			# Inicia la animación
			download_tween.tween_property(download_bar, "value", 100.0, duracion_descarga)
			
			# ¡Y ESPERA (await) a que termine!
			# El script se pausará aquí por 'duracion_descarga' segundos
			await download_tween.finished
			
			print("Acción: Descarga terminada.")
			
		# Ya no necesitamos [ACCION_INICIAR_DESCARGA]

		"[ACCION_SONIDO_MENSAJE]":
			print("Acción: Sonido de mensaje")
			await get_tree().create_timer(2.0).timeout
			message_sound.play()
			await get_tree().create_timer(1.0).timeout

# --- Fin de la Cinemática ---
func _end_cinematic():
	print("Cinemática terminada. Cargando LoaderScene.")
	# Cambia a tu escena principal (el escritorio interactivo)
	get_tree().change_scene_to_file("res://escenas/loader_scene.tscn")
