extends Control

@onready var glitch_layer: ColorRect = $GlitchLayer
@onready var glitch_sound: AudioStreamPlayer = $GlitchSound
@onready var video_player: VideoStreamPlayer = $VideoPlayer

func _ready():
	video_player.hide()
	glitch_layer.show()
	
	start_glitch_sequence()

func start_glitch_sequence():
	glitch_sound.play()
	await glitch_sound.finished 
	
	start_video_sequence()

func start_video_sequence():
	glitch_layer.hide()
	video_player.show()
	video_player.play()
	
	if not video_player.finished.is_connected(_on_video_finished):
		video_player.finished.connect(_on_video_finished)

func _on_video_finished():
	print("Video terminado. Cerrando juego.")
	get_tree().quit()
