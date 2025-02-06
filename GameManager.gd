extends Node2D

var obstacle_move_speed = -400
var spawn_speed = 2.25

#initial move : -400 and spawn : 2.25

@onready var spawn_timer = $SpawnTimer
@onready var obstacle_parent = $Obstacles
@onready var obstacle_prefab = load("res://Obstacle.tscn")

func _ready():
	spawn_timer.wait_time = spawn_speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for obstacle in obstacle_parent.get_children():
		obstacle.global_position.x += obstacle_move_speed * delta
		if obstacle.global_position.x < -700:
			obstacle.queue_free()

func on_spawn_timer_timeout():
	var obstacle = obstacle_prefab.instantiate()
	obstacle_parent.add_child(obstacle)
	obstacle.global_position = Vector2(1500, 148.25)
	
