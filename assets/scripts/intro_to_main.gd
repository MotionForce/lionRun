extends Control

var game_scene = preload("res://assets/Game_Scene.tscn").instantiate()

func _input(event):
	if event is InputEventKey || event is InputEventMouseButton:
		print (event.as_text())
		if event.pressed:
			get_tree().change_scene_to_file("res://assets/Game_Scene.tscn")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "intro_sequence":
		print("Animation finished")
		get_tree().change_scene_to_file("res://assets/Game_Scene.tscn")
