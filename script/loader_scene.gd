extends Control

@export var chat_ui_scene: PackedScene
@onready var icono_msn: TextureButton = %IconoMSN
@onready var chat_window: Window = %ChatWindow
@onready var world_dialogue_bubble = %WorldDialogueBubble

var world_dialogue_resource = preload("res://dialogue/world_dialogue.dialogue")

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
func _on_icono_msn_pressed():
	# 1. MUESTRA EL PENSAMIENTO PRIMERO
	trigger_thought("encender_pc")
	# 2. ESPERA UN POCO
	await get_tree().create_timer(2.0).timeout
	# 3. ABRE LA VENTANA DEL CHAT DESPUÉS
	chat_window.popup_centered()
	# --- FIN INTEGRACIÓN ---

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
