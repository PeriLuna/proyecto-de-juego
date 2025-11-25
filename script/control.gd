extends Control

@export var game_scene: PackedScene

@onready var buttons_container: CenterContainer = $ButtonsContainer
@onready var exit_video: VideoStreamPlayer = $ExitSequenceVideo
@onready var background_video: VideoStreamPlayer = $BackgroundVideo
@onready var musica_fondo: AudioStreamPlayer = $AudioStreamPlayer 

func _ready():
	$ButtonsContainer/VBoxButtons/PlayButton.focus_mode = Control.FOCUS_NONE
	$ButtonsContainer/VBoxButtons/ExitButton.focus_mode = Control.FOCUS_NONE

func _on_play_button_pressed():
	if musica_fondo: musica_fondo.stop() 
	background_video.stop()
	
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("Error: No asignaste la escena del juego en el Inspector.")

func _on_exit_button_pressed():
	buttons_container.hide()
	background_video.stop()
	
	if musica_fondo:
		musica_fondo.stop()
	
	exit_video.show()
	exit_video.play()
	
	get_viewport().set_input_as_handled()

func _on_exit_sequence_video_finished():
	get_tree().quit()
