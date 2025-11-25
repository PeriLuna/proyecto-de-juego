extends Control

# --- Escenas y Recursos ---
var world_dialogue_resource = preload("res://dialogue/world_dialogue.dialogue")
var chica_desconocida_resource = preload("res://dialogue/chica_desconocida.dialogue")

# --- Texturas de Cinemática ---
var tex_xp_boot_1 = preload("res://Arte/Fondos/XP.png")
var tex_xp_boot_2 = preload("res://Arte/Fondos/Inicio.png")
var tex_xp_boot_3 = preload("res://Arte/Fondos/Fondo.jpg")

# --- Referencias a Nodos ---
@onready var world_dialogue_bubble = %CanvasLayer/WorldDialogueBubble
@onready var login_screen: TextureRect = %LoginScreen
@onready var sound_player: AudioStreamPlayer = %SoundPlayer
@onready var pre_intro_layer: CanvasLayer = %PreIntroLayer
@onready var info_text: Label = %InfoText

# Sonidos
@export var msn_buzz_sound: AudioStream = preload("res://Arte/Sonidos/MSN Messenger sound.mp3")
@export var xp_startup_sound: AudioStream = preload("res://Arte/Sonidos/Windows XP.mp3")

func _ready():
	start_intro_cinematic()

func start_intro_cinematic():
	pre_intro_layer.show()
	
	# 1. Pantalla de Controles
	info_text.visible_characters = -1 
	info_text.text = "CONTROLES\n\nUsa el CLICK IZQUIERDO para interactuar con el chat.\nUsa el TECLADO para tomar decisiones.\n\nCreado/Desarrolado por: \nLuna, Pericles \nEchaugüe, Rocio \nSantillan, Luca"
	await get_tree().create_timer(10.0).timeout 
	
	# 2. Pantalla Narrativa
	info_text.text = "" 
	await get_tree().create_timer(0.5).timeout
	
	var historia = "Jamás me olvidaré de esa noche...\n el sonido de esa notificación me dejaba loco."
	await _type_text_on_label(info_text, historia, 0.06)
	await get_tree().create_timer(2.7).timeout
	
	pre_intro_layer.hide()
	
	
	# --- PARTE 1: SECUENCIA DE ENCENDIDO ---
	print("Iniciando secuencia XP...")
	login_screen.texture = tex_xp_boot_1
	login_screen.show()
	await get_tree().create_timer(2.0).timeout 
	
	login_screen.texture = tex_xp_boot_2
	await get_tree().create_timer(2.4).timeout 
	
	login_screen.texture = tex_xp_boot_3
	sound_player.stream = xp_startup_sound
	sound_player.play()
	await get_tree().create_timer(3.0).timeout 
	
	login_screen.hide()
	print("Secuencia XP terminada.")

	# --- PARTE 2: SECUENCIA DE TEXTO RETRO ---
	await _show_retro_text("intro_pc_1")
	await _show_retro_text("intro_pc_2")
	await _show_retro_text("intro_pc_3")
	
	# --- PARTE 3: FINAL ---
	sound_player.stream = msn_buzz_sound
	sound_player.play()
	await sound_player.finished
	
	print("Cinemática terminada. Cargando LoaderScene.")
	get_tree().change_scene_to_file("res://escenas/loader_scene.tscn")

func _type_text_on_label(label: Label, text_content: String, speed: float):
	label.text = text_content
	label.visible_characters = 0
	
	for i in range(text_content.length()):
		label.visible_characters += 1
		
		await get_tree().create_timer(speed).timeout
	
	label.visible_characters = -1


# --- Helper para mostrar texto retro ---
func _show_retro_text(title: String):
	var line = await DialogueManager.get_next_dialogue_line(world_dialogue_resource, title)
	if line:
		world_dialogue_bubble.show_line(line.text) 
		await world_dialogue_bubble.thought_hidden
		await get_tree().create_timer(0.5).timeout
