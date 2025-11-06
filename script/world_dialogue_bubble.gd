extends PanelContainer

# --- Nodos Hijo (¡Usa Nombres Únicos!) ---
@onready var dialogue_text: Label = %DialogueText

# --- Variable de estado ---
var is_showing: bool = false

func _ready():
	hide() # Asegura que empieza oculto

# --- Función Pública para mostrar una línea ---
func show_line(line_text: String):
	dialogue_text.text = line_text
	show()
	is_showing = true

# --- Función Pública para ocultar ---
func hide_bubble():
	hide()
	is_showing = false
