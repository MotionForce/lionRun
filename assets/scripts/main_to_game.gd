extends Control

var game_scene = preload("res://assets/Game_Scene.tscn").instantiate()
@onready var on_click_play = $OnClickPlay
@onready var main_menu_theme = $MainMenuTheme

func _on_button_pressed():
	on_click_play.play()
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://assets/Game_Scene.tscn")

func loop_main_menu_theme():
	main_menu_theme.play()
