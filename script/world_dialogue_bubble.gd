extends PanelContainer

# --- Señales ---
signal thought_shown
signal thought_hidden

@onready var dialogue_text: Label = %DialogueText
@onready var display_timer: Timer = %DisplayTimer

var is_showing: bool = false

func _ready():
	display_timer.timeout.connect(_on_display_timer_timeout)
	hide()
	
# Llama a esta función desde otros scripts
func show_line(line_text: String, duration: float = 4.0):
	# Si ya se está mostrando, cancela el timer anterior
	if is_showing:
		display_timer.stop()

	dialogue_text.text = line_text
	show()
	is_showing = true
	emit_signal("thought_shown")

	# Inicia el timer para ocultarlo automáticamente
	display_timer.wait_time = duration
	display_timer.start()

# --- Ocultar al terminar el Timer ---
func _on_display_timer_timeout():
	_hide_bubble()

# --- PRUEBA para ocultar, presionar Enter/Clic ---
func _input(event):
	# Si se muestra Y se presiona la acción de aceptar...
	if is_showing and event.is_action_pressed("ui_accept"):
		_hide_bubble()
		get_viewport().set_input_as_handled()

# --- Función interna para ocultar ---
func _hide_bubble():
	if is_showing:
		display_timer.stop() # Detiene el timer por si se llamó antes
		emit_signal("thought_hidden") # Avisa que se va a ocultar
		hide()
		is_showing = false
