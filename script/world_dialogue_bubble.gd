extends PanelContainer

# --- Señales ---
signal thought_shown
signal thought_hidden

# --- Nodos ---
@onready var dialogue_text: Label = %DialogueText
@onready var display_timer: Timer = %DisplayTimer

# --- Variable de estado ---
var is_showing: bool = false
var waits_for_input: bool = false

func _ready():
	display_timer.timeout.connect(_on_display_timer_timeout)
	hide()
	display_timer.autostart = false

# --- MODO "PENSAMIENTO" ---
func show_line(line_text: String, duration: float = 4.0):
	if is_showing: display_timer.stop()
	dialogue_text.text = line_text
	show()
	is_showing = true
	waits_for_input = false
	emit_signal("thought_shown")
	display_timer.wait_time = duration
	display_timer.start()

# --- MODO "CINEMÁTICA" ---
func show_and_wait(line_text: String):
	if is_showing: display_timer.stop()
	dialogue_text.text = line_text
	show()
	is_showing = true
	waits_for_input = true
	emit_signal("thought_shown")

func _on_display_timer_timeout():
	_hide_bubble()

func _input(event):
	if is_showing and waits_for_input and event.is_action_pressed("ui_accept"):
		_hide_bubble()
		get_viewport().set_input_as_handled()

func _hide_bubble():
	if is_showing:
		display_timer.stop()
		emit_signal("thought_hidden")
		hide()
		is_showing = false
		waits_for_input = false
