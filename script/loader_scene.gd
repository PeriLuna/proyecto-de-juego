extends Control

# --- Escenas y Recursos ---
@export var chat_ui_scene: PackedScene
var world_dialogue_resource = preload("res://dialogue/world_dialogue.dialogue")
var chica_desconocida_resource = preload("res://dialogue/chica_desconocida.dialogue")

# --- Variable Local de Estado ---
var current_background_local: String = "default"

# --- Texturas de Splash ---
var tex_login_4 = preload("res://Arte/Fondos/4.png") 

# --- FONDOS DE ESCRITORIO ---
# Asegúrate de que las extensiones (.jpg / .png) coincidan con tus archivos reales
var bg_normal = preload("res://Arte/Fondos/Fondo.jpg")
var bg_miedo = preload("res://Arte/Fondos/FondoMiedo.png")
var bg_hacked = preload("res://Arte/Fondos/FondoHackeo.jpg") # Si es .jpg, cámbialo aquí

# --- MÚSICA ---
var music_normal = preload("res://Arte/Sonidos/version Cyberpunk chill.wav")
var music_miedo = preload("res://Arte/Sonidos/Miedo.mp3")
var music_hacked = preload("res://Arte/Sonidos/Miedo.mp3") 

# --- Referencias a Nodos ---
@onready var icono_msn: TextureButton = %MSN 
@onready var chat_window: Window = %ChatWindow
@onready var world_dialogue_bubble = %CanvasLayer/WorldDialogueBubble
@onready var login_screen: TextureRect = %LoginScreen 
@onready var fondo: TextureRect = $Fondo 
@onready var sound_player: AudioStreamPlayer = %SoundPlayer 
@onready var music_player: AudioStreamPlayer = %MusicPlayer 
@onready var noti: TextureRect = %Noti # Referencia a la notificación

# --- Variables ---
var chat_instance: Control
var msn_first_open: bool = true 

func _ready():
	# Configuraciones iniciales
	chat_window.close_requested.connect(_on_chat_window_close_requested)
	icono_msn.pressed.connect(_on_icono_msn_pressed)
	icono_msn.disabled = false 
	login_screen.hide()
	noti.hide() # Asegura que la noti empiece oculta
	
	# Aplicar estado inicial (Fondo y Música)
	_apply_game_state(current_background_local)

	# Instanciar y conectar Chat
	if chat_ui_scene:
		chat_instance = chat_ui_scene.instantiate()
		chat_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
		chat_window.add_child(chat_instance)
		
		if chat_instance.has_signal("thought_requested"):
			chat_instance.thought_requested.connect(trigger_thought)
		
		if chat_instance.has_signal("background_change_requested"):
			chat_instance.background_change_requested.connect(_on_background_change)
			
		if world_dialogue_bubble and chat_instance.has_method("pause_for_thought"):
			world_dialogue_bubble.thought_shown.connect(chat_instance.pause_for_thought)
			world_dialogue_bubble.thought_hidden.connect(chat_instance.resume_after_thought)
	else:
		print("¡ERROR! No se asignó la escena 'chat_ui_scene' en el Inspector.")

	# --- MOSTRAR NOTIFICACIÓN AL INICIO ---
	show_notification_sequence()


# --- FUNCIÓN UNIFICADA PARA APLICAR ESTADOS ---
func _apply_game_state(state: String):
	match state:
		"default":
			fondo.texture = bg_normal
			_play_music(music_normal)
		"miedo":
			fondo.texture = bg_miedo
			_play_music(music_miedo)
		"hacked":
			fondo.texture = bg_hacked
			_play_music(music_hacked)

# --- FUNCIÓN PARA CAMBIAR MÚSICA INTELIGENTEMENTE ---
func _play_music(stream: AudioStream):
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

# --- Función para cambiar el fondo (Recibe señal del Chat) ---
func _on_background_change(bg_code: String):
	print("LoaderScene: Recibido código ", bg_code)
	match bg_code:
		"[BG_NORMAL]": current_background_local = "default"
		"[BG_MIEDO]": current_background_local = "miedo"
		"[BG_HACKED]": current_background_local = "hacked"
	_apply_game_state(current_background_local)


# --- FUNCIÓN DE NOTIFICACIÓN ---
func show_notification_sequence():
	# Busca los nodos hijos de la notificación
	var noti_audio = noti.get_node_or_null("AudioStreamPlayer") 
	var noti_timer = noti.get_node_or_null("Timer")
	
	if noti_audio: noti_audio.play()
	noti.show()
	
	if noti_timer:
		noti_timer.start()
		await noti_timer.timeout
	else:
		await get_tree().create_timer(2.0).timeout
	
	noti.hide()


# --- Función del Botón MSN ---
func _on_icono_msn_pressed():
	if chat_window.visible: return
	if world_dialogue_bubble.is_showing: return
	if msn_first_open: abrir_msn_con_splash()
	else: chat_window.popup_centered()

# --- Splash Screen de MSN ---
func abrir_msn_con_splash():
	login_screen.set_anchors_preset(Control.PRESET_CENTER) 
	login_screen.texture = tex_login_4
	login_screen.show()
	await get_tree().create_timer(1.0).timeout
	login_screen.hide()
	chat_window.popup_centered()
	
	if msn_first_open: 
		if chat_instance.has_method("start_specific_chat"):
			chat_instance.start_specific_chat("ChicaDesconocida_92", chica_desconocida_resource, "inicio")
		msn_first_open = false 

# --- Cerrar Ventana ---
func _on_chat_window_close_requested():
	chat_window.hide()

# --- Mostrar Pensamiento ---
func trigger_thought(thought_title: String):
	if not is_instance_valid(world_dialogue_bubble):
		print("Error: WorldDialogueBubble no es válido.")
		return
	var line = await DialogueManager.get_next_dialogue_line(world_dialogue_resource, thought_title)
	if line: world_dialogue_bubble.show_line(line.text)

# --- Input de Prueba ---
func _input(event):
	if event.is_action_pressed("ui_accept") and not chat_window.visible: pass
