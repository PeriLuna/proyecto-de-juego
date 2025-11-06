extends Control

@export var chat_ui_scene: PackedScene
@onready var icono_msn: TextureButton = %IconoMSN
@onready var chat_window: Window = %ChatWindow
@onready var world_dialogue_bubble = %WorldDialogueBubble
@onready var login_screen: TextureRect = %LoginScreen

var world_dialogue_resource = preload("res://dialogue/world_dialogue.dialogue")
var tex_login_4 = preload("res://Arte/Fondos/4.png")
var tex_login_5 = preload("res://Arte/Fondos/5.png")
var tex_login_6 = preload("res://Arte/Fondos/6.png")
# Guardamos la instancia del chat (si necesitas pausarla en el futuro)
var chat_instance: Control

func _ready():
	# 1. Conecta la señal del botón MSN
	icono_msn.pressed.connect(_on_icono_msn_pressed)
	# Conecta la señal de cerrar la ventana de chat
	chat_window.close_requested.connect(_on_chat_window_close_requested)

	# 2. Prepara la ventana de chat (la creamos una sola vez)
	if chat_ui_scene:
		# Instancia la escena de chat
		chat_instance = chat_ui_scene.instantiate()
		chat_instance.set_anchors_preset(Control.PRESET_FULL_RECT)
		chat_window.add_child(chat_instance)
	else:
		print("¡ERROR! No se asignó la escena 'chat_ui_scene' en el Inspector.")


# --- Función llamada al presionar el icono MSN ---
# --- Función llamada al presionar el icono MSN ---
func _on_icono_msn_pressed():
	
	# Si la ventana de chat ya está visible, no hacemos nada
	if chat_window.visible:
		return
	
	# Si el globo de pensamiento está visible, no hacemos nada
	if world_dialogue_bubble.is_showing:
		return
	
	# Muestra el pensamiento "Voy a encender la compu..."
	trigger_thought("encender_pc")
	
	# --- INICIO DE LA SECUENCIA ---
	# Espera 2 segundos a que se lea el pensamiento
	await get_tree().create_timer(2.0).timeout
	
	# 1. Muestra la imagen 4
	print("Mostrando imagen 4")
	login_screen.texture = tex_login_4
	login_screen.show()
	
	# Espera 2 segundos
	await get_tree().create_timer(2.0).timeout
	
	# 2. Muestra la imagen 5
	print("Mostrando imagen 5")
	login_screen.texture = tex_login_5
	
	# Espera 1 segundo
	await get_tree().create_timer(4.0).timeout
	
	# 3. Muestra la imagen 6
	print("Mostrando imagen 6")
	login_screen.texture = tex_login_6
	
	# Espera 1 segundo
	await get_tree().create_timer(2.0).timeout
	
	# 4. Oculta la secuencia y abre el chat
	print("Abriendo ChatWindow")
	login_screen.hide()
	chat_window.popup_centered()
	# --- FIN DE LA SECUENCIA ---

func _on_chat_window_close_requested():
	chat_window.hide()

# --- Función para MOSTRAR un pensamiento ---
func trigger_thought(thought_title: String):
	# Asegúrate de que la burbuja exista antes de usarla
	if not is_instance_valid(world_dialogue_bubble):
		print("Error: WorldDialogueBubble no es válido.")
		return

	var line = await DialogueManager.get_next_dialogue_line(world_dialogue_resource, thought_title)
	if line:
		world_dialogue_bubble.show_line(line.text) # Muestra el texto

# --- PRUEBA DE OENSAMIENTO ---
func _input(event):
	# Si presionas Enter Y el chat NO está visible... (para no interferir)
	if event.is_action_pressed("ui_accept") and not chat_window.visible:
		print("Disparando pensamiento de prueba...")
		trigger_thought("mirar_ventana")
		get_viewport().set_input_as_handled()
