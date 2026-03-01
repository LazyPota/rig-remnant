extends Node2D

@onready var result_title = $ResultTitle
@onready var result_message = $ResultMessage
@onready var play_again_button = $PlayAgainButton
@onready var main_menu_button = $MainMenuButton

var is_victory: bool = false
var final_message: String = ""

func _ready() -> void:
	show_result()

func show_result():
	if is_victory:
		result_title.text = "VICTORY!"
		result_title.modulate = Color.GREEN
		result_message.text = "Selamat! Anda berhasil bertahan selama 15 minggu!\n\n" + final_message
	else:
		result_title.text = "GAME OVER"
		result_title.modulate = Color.RED
		result_message.text = final_message

func set_result(victory: bool, message: String):
	is_victory = victory
	final_message = message

func _on_play_again_button_pressed() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
