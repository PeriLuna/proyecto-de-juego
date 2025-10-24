extends VBoxContainer

# --- Variables ---
@export var typing_speed: float = 0.05

# --- Nodos Hijo (¡Usa Nombres Únicos!) ---
@onready var name_panel: PanelContainer = %NamePanel
@onready var name_label: Label = %NameLabel
@onready var bubble_panel: PanelContainer = %BubblePanel
@onready var dialogue_label: Label = %DialogueLabel
@onready var typing_timer: Timer = %TypingTimer # Timer solo para el jugador

# Variables internas
var full_text: String = ""
var current_char: int = 0

# --- Inicialización ---
func _ready():
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	# Muestra todo por defecto (lo ocultará si empieza a tipear)
	name_panel.show()
	bubble_panel.show()


# --- Funciones Públicas ---

# Para mostrar el texto del NPC de golpe
func show_instantly(character: String, text: String):
	name_label.text = character
	dialogue_label.text = text
	dialogue_label.visible_characters = -1 # Muestra todo

# Para iniciar el tipeo del jugador
func start_typing(character: String, text: String):
	full_text = text
	name_label.text = character
	dialogue_label.text = full_text
	dialogue_label.visible_characters = 0 # Oculta texto
	current_char = 0
	typing_timer.wait_time = typing_speed
	typing_timer.one_shot = false # Asegúrate que no sea one_shot
	typing_timer.start()


# --- Señal del Timer (SOLO para el jugador) ---
func _on_typing_timer_timeout():
	current_char += 1
	dialogue_label.visible_characters = current_char
	if current_char >= full_text.length():
		typing_timer.stop()
