extends Node2D


@onready var music_player: AudioStreamPlayer = $MusicBarracs
@onready var sfx_player: AudioStreamPlayer = $SoundEffect


var menu_music = preload('res://assets/Audio/Audio/Ambience/Menu Music.ogg')
var click_sound = preload('res://assets/Audio/Audio/UI Sounds/Retro7.ogg')


func _start_menu_music():
	if music_player and menu_music:
		music_player.stream = menu_music
		music_player.volume_db = -8.0
		#looping jika format music ogg
		if music_player.stream is AudioStreamOggVorbis:
			music_player.stream.loop = true
		music_player.play()

func play_click():
	if sfx_player and click_sound:
		sfx_player.stream = click_sound
		sfx_player.play()

func _ready():
	_start_menu_music()

func _on_new_game_button_pressed():
	play_click()
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/base_level.tscn")

func _on_continue_button_pressed():
	play_click()
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/base_level.tscn")

func _on_tombol_button_pressed():
	play_click()
	get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_quit_button_pressed():
	play_click()
	get_tree().quit()
