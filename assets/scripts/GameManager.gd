extends Node2D

const OBSTACLE_MAX_SPEED = -1200
const OBSTACLE_ACCELERATION = -4
const INITIAL_MOVE_SPEED = -600 #cannot be equal to obstacle_max_speed -> division by 0

var obstacle_move_speed = -600
var speed_progression = 0

var next_obstacle = null
var cannon_balls_stack = []
var previous_obstacle = null
var previous_cannon_balls_stack = []
var distance_to_spawn = 0;
var random = RandomNumberGenerator.new()

var game_time = 0
var obstacle_queued = 0

var obstacle_prefab_path = [
	"res://assets/prefabs/Cannon.tscn",
	"res://assets/prefabs/Ring.tscn",
	"res://assets/prefabs/Trapeze.tscn"
]
var cannon_ball_prefab_path = "res://assets/prefabs/Cannon_ball.tscn"

var ground_global_y = 0
var initial_position = Vector2(1500, -35)

@onready var player_controller = $Player/CharacterBody2D
@onready var obstacle_parent = $Obstacles
@onready var obstacle_preload = $"Preloaded Obstacles"
@onready var ground = $Ground
@onready var background_music = $BackgroundMusic
@onready var score_display = $UI/ScoreBox/Score
@onready var gold_display = $UI/GoldBox/Gold
@onready var time_display = $UI/TimeBox/Time
@onready var jump1 = $UI/Jump1
@onready var jump2 = $UI/Jump2
@onready var death_screen = $DeathScreen
@onready var scaffold = $Scaffold


func _ready():
	death_screen.visible = false
	obstacle_move_speed = INITIAL_MOVE_SPEED
	determine_ground_y()
	determine_next_obstacle()
	jump1.max_value = (player_controller.timer1.get_wait_time() - player_controller.time_for_fast_jump)
	jump2.max_value = (player_controller.timer2.get_wait_time() - player_controller.time_for_fast_jump)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	determine_spawn()
	scaffold.global_position.x += obstacle_move_speed * delta / 3
	if scaffold.global_position.x < -1152:
		scaffold.global_position.x = 0
	for obstacle in obstacle_parent.get_children():
		obstacle.global_position.x += obstacle_move_speed * delta
		if obstacle.global_position.x < -700:
			get_node("Player/CharacterBody2D").on_queue_free_obstacle(obstacle)
			obstacle_queued += 1
			obstacle.queue_free()
	score_display.text = str(player_controller.score)
	gold_display.text = str(player_controller.gold)
	time_display.text = get_game_time()
	jump1.value = (player_controller.e_hold_time_1 - player_controller.time_for_fast_jump) / (player_controller.timer1.get_wait_time() - player_controller.time_for_fast_jump)
	jump2.value = (player_controller.e_hold_time_2 - player_controller.time_for_fast_jump) / (player_controller.timer2.get_wait_time() - player_controller.time_for_fast_jump)

func update_speed_progression():
	speed_progression = float(obstacle_move_speed - INITIAL_MOVE_SPEED) / float(OBSTACLE_MAX_SPEED - INITIAL_MOVE_SPEED)

func determine_next_obstacle():
	var obstacle = load(obstacle_prefab_path[random.randi_range(0, obstacle_prefab_path.size()-1)])
	next_obstacle = obstacle.instantiate()
	obstacle_preload.add_child(next_obstacle)
	next_obstacle.global_position = initial_position
	determine_height_of_obstacle()
	determine_if_stick()
	determine_stack()
	determine_distance_to_spawn()

func determine_spawn():
	var distance_from_previous_obstacle = 0
	if previous_obstacle != null:
		distance_from_previous_obstacle = next_obstacle.global_position.x - previous_obstacle.global_position.x
	else:
		distance_from_previous_obstacle = distance_to_spawn
	
	if next_obstacle.is_in_group("Queue_Stick") && distance_from_previous_obstacle > 130:
		spawn_next_obstacle()
	elif distance_from_previous_obstacle >= distance_to_spawn:
		spawn_next_obstacle()

func spawn_next_obstacle():
	if next_obstacle != null:
		if next_obstacle.is_in_group("Queue_Stick"):
			next_obstacle.remove_from_group("Stickable")
		
		obstacle_preload.remove_child(next_obstacle)
		obstacle_parent.add_child(next_obstacle)
		previous_obstacle = next_obstacle
		for cannon_ball in cannon_balls_stack:
			obstacle_preload.remove_child(cannon_ball)
			obstacle_parent.add_child(cannon_ball)
		previous_cannon_balls_stack = cannon_balls_stack
		cannon_balls_stack = []
	determine_next_obstacle()
	

func _on_game_timer_timeout():
	game_time += 1
	get_game_time()
	if obstacle_move_speed > OBSTACLE_MAX_SPEED:
		obstacle_move_speed += OBSTACLE_ACCELERATION
		update_speed_progression()

func determine_height_of_obstacle():
	var sprite2D = next_obstacle.get_node("Sprite2D")
	sprite2D.position.y = random.randf_range(sprite2D.position.y, 0)

func determine_ground_y():
	var shape = ground.get_node("CollisionShape2D")
	ground_global_y = shape.global_position.y - (shape.shape.size.y / 2)

func determine_if_stick():
	if previous_obstacle == null:
		return
	if previous_obstacle.is_in_group("Stickable") == false:
		return
	if next_obstacle.is_in_group("Stickable") == false && (next_obstacle.is_in_group("Ring") == false || previous_obstacle.is_in_group("Trapeze") == false):
		return
	
	var obstacle_minimum_jump = ground_global_y - next_obstacle.get_node("Sprite2D/Minimal Jump").global_position.y
	var smallest_height = 5000
	for cannon_ball in previous_cannon_balls_stack:
		var minimum_jump_distance = cannon_ball.get_node("Sprite2D/Area2D/CollisionShape2D").global_position.distance_to(cannon_ball.get_node("Sprite2D/Minimum Jump Distance").global_position)
		var cannon_ball_height = ground_global_y - cannon_ball.get_node("Sprite2D").global_position.y - (cannon_ball.get_node("Sprite2D").get_offset().y * cannon_ball.get_node("Sprite2D").scale.y) + minimum_jump_distance
		if cannon_ball_height < smallest_height:
			smallest_height = cannon_ball_height
	if obstacle_minimum_jump > smallest_height:
		return
		
	var random_num = random.randi_range(0, 3)
	if random_num == 3:
		next_obstacle.add_to_group("Queue_Stick")

func determine_distance_to_spawn():
	var minimal_jump_height = ground_global_y - next_obstacle.get_node("Sprite2D/Minimal Jump").global_position.y
	var minimal_jump_height_previous_obstacle = 0
	if previous_obstacle != null:
		minimal_jump_height_previous_obstacle = ground_global_y - previous_obstacle.get_node("Sprite2D/Minimal Jump").global_position.y
		if previous_obstacle.is_in_group("Queue_Stick"):
			minimal_jump_height_previous_obstacle += 60
	
	var max_extra_time = 0.5 * (2 - speed_progression)
	
	var minimum_distance = (minimal_jump_height + minimal_jump_height_previous_obstacle) * (2.25 + 2 * pow(speed_progression -0.3, 2))
	var maximum_distance = minimum_distance - obstacle_move_speed * max_extra_time
	
	distance_to_spawn = random.randf_range(minimum_distance, maximum_distance)

func determine_stack():
	var minimal_jump_height = ground_global_y - next_obstacle.get_node("Sprite2D/Minimal Jump").global_position.y
	var cannon_ball_prefab = load(cannon_ball_prefab_path)
	var random_num = random.randi_range(0, 9)
	
	if next_obstacle.is_in_group("Queue_Stick") || random_num < 6 - (3 * speed_progression):
		return
	
	var cannon_ball = cannon_ball_prefab.instantiate()
	obstacle_preload.add_child(cannon_ball)
	cannon_ball.global_position = initial_position
	var minimum_distance_from_jump = cannon_ball.get_node("Sprite2D/Area2D/CollisionShape2D").global_position.distance_to(cannon_ball.get_node("Sprite2D/Minimum Jump Distance").global_position)
	var minimum_stack_distance = cannon_ball.get_node("Sprite2D/Area2D/CollisionShape2D").global_position.distance_to(cannon_ball.get_node("Sprite2D/Minimum Stack Distance").global_position)
	var cannon_ball_maximum_height = cannon_ball.get_node("Sprite2D").global_position.y + (cannon_ball.get_node("Sprite2D").get_offset().y * cannon_ball.get_node("Sprite2D").scale.y)
	
	if next_obstacle.is_in_group("Ring"):
		determine_cannon_ball_above_ring(cannon_ball_maximum_height, minimum_distance_from_jump, minimal_jump_height, minimum_stack_distance)
		cannon_ball.get_node("Sprite2D").position.y = 0
		var cannon_ball_minimum_height = cannon_ball.get_node("Sprite2D").global_position.y + (cannon_ball.get_node("Sprite2D").get_offset().y * cannon_ball.get_node("Sprite2D").scale.y)
		determine_cannon_ball_below_ring(cannon_ball_minimum_height, minimum_distance_from_jump, minimal_jump_height, minimum_stack_distance)
	
	else:
		determine_general_cannon_ball_stack(cannon_ball_maximum_height, minimum_distance_from_jump, minimal_jump_height, minimum_stack_distance)
	cannon_ball.queue_free()

func determine_cannon_ball_below_ring(minimum_height, minimum_distance_from_jump, ring_height, minimum_stack_distance):
	var minimum_ring_height = ground_global_y - minimum_height + minimum_distance_from_jump
	if ring_height < minimum_ring_height:
		return
	var minimum_ring_height_for_doubles = minimum_ring_height + minimum_stack_distance
	var random_num = random.randi_range(0, 9)
	var cannon_ball_prefab = load(cannon_ball_prefab_path)
	
	if ring_height > minimum_ring_height_for_doubles && random_num < 3 + (3 * speed_progression):
		var cannon_balls = [cannon_ball_prefab.instantiate(), cannon_ball_prefab.instantiate()]
		var free_space = ring_height - minimum_ring_height_for_doubles
		for cannon_ball in cannon_balls:
			obstacle_preload.add_child(cannon_ball)
			cannon_ball.global_position = initial_position
		
		cannon_balls[0].get_node("Sprite2D").position.y = 0
		var max_height = ground_global_y - ring_height + minimum_distance_from_jump - (cannon_balls[0].get_node("Sprite2D").get_offset().y * cannon_balls[0].get_node("Sprite2D").scale.y)
		cannon_balls[0].get_node("Sprite2D").global_position.y = random.randf_range(max_height, max_height + free_space)
		cannon_balls[1].get_node("Sprite2D").global_position.y = cannon_balls[0].get_node("Sprite2D").global_position.y + minimum_stack_distance
		cannon_balls_stack.append_array(cannon_balls)
	
	elif random_num < 7 + (3 * speed_progression):
		var cannon_ball = cannon_ball_prefab.instantiate()
		obstacle_preload.add_child(cannon_ball)
		cannon_ball.global_position = initial_position
		
		var sprite2D = cannon_ball.get_node("Sprite2D")
		sprite2D.position.y = 0
		var max_height = ground_global_y - ring_height + minimum_distance_from_jump - (cannon_ball.get_node("Sprite2D").get_offset().y * cannon_ball.get_node("Sprite2D").scale.y)
		sprite2D.global_position.y = random.randf_range(max_height, sprite2D.global_position.y)
		cannon_balls_stack.append(cannon_ball)
	
func determine_cannon_ball_above_ring(maximum_height, minimum_distance_from_jump, ring_height, minimum_stack_distance):
	var maximum_ring_height = ground_global_y - maximum_height - minimum_distance_from_jump
	if ring_height > maximum_ring_height:
		return
	var maximum_ring_height_for_doubles = maximum_ring_height - minimum_distance_from_jump
	var random_num = random.randi_range(0, 9)
	var cannon_ball_prefab = load(cannon_ball_prefab_path)
	
	if ring_height < maximum_ring_height_for_doubles && random_num < 3 + (3 * speed_progression):
		var cannon_balls = [cannon_ball_prefab.instantiate(), cannon_ball_prefab.instantiate()]
		for cannon_ball in cannon_balls:
			obstacle_preload.add_child(cannon_ball)
			cannon_ball.global_position = initial_position
		
		var min_height = ground_global_y - ring_height - minimum_distance_from_jump - (cannon_balls[0].get_node("Sprite2D").get_offset().y * cannon_balls[0].get_node("Sprite2D").scale.y)
		cannon_balls[0].get_node("Sprite2D").global_position.y = random.randf_range(cannon_balls[0].get_node("Sprite2D").global_position.y, min_height - minimum_stack_distance)
		cannon_balls[1].get_node("Sprite2D").global_position.y = cannon_balls[0].get_node("Sprite2D").global_position.y + minimum_stack_distance
		cannon_balls_stack.append_array(cannon_balls)
		
	elif random_num < 7 + (3 * speed_progression):
		var cannon_ball = cannon_ball_prefab.instantiate()
		obstacle_preload.add_child(cannon_ball)
		cannon_ball.global_position = initial_position
		
		var sprite2D = cannon_ball.get_node("Sprite2D")
		var min_height = ground_global_y - ring_height - minimum_distance_from_jump - (cannon_ball.get_node("Sprite2D").get_offset().y * cannon_ball.get_node("Sprite2D").scale.y)
		sprite2D.global_position.y = random.randf_range(sprite2D.global_position.y, min_height)
		cannon_balls_stack.append(cannon_ball)

func determine_general_cannon_ball_stack(maximum_height, minimum_distance_from_jump, obstacle_height, minimum_stack_distance):
	var available_space = ground_global_y - maximum_height - minimum_distance_from_jump - obstacle_height - (obstacle_height * 1.2 * (1 - speed_progression))
	if available_space < 0:
		return
	var minimum_space_for_double = minimum_stack_distance
	var minimum_space_for_tripe = minimum_space_for_double + minimum_stack_distance
	var random_num = random.randi_range(0, 9)
	var cannon_ball_prefab = load(cannon_ball_prefab_path)

	if available_space >= minimum_space_for_tripe && random_num < 1 + (2 * speed_progression):
		var cannon_balls = [cannon_ball_prefab.instantiate(), cannon_ball_prefab.instantiate(), cannon_ball_prefab.instantiate()]
		for cannon_ball in cannon_balls:
			obstacle_preload.add_child(cannon_ball)
			cannon_ball.global_position = initial_position
		
		cannon_balls[0].get_node("Sprite2D").global_position.y = random.randf_range(cannon_balls[0].get_node("Sprite2D").global_position.y, cannon_balls[0].get_node("Sprite2D").global_position.y + available_space - (2 * minimum_stack_distance))
		cannon_balls[1].get_node("Sprite2D").global_position.y = cannon_balls[0].get_node("Sprite2D").global_position.y + minimum_stack_distance
		cannon_balls[2].get_node("Sprite2D").global_position.y = cannon_balls[1].get_node("Sprite2D").global_position.y + minimum_stack_distance
		cannon_balls_stack.append_array(cannon_balls)
	elif available_space >= minimum_space_for_double && random_num < 4 + (3 * speed_progression):
		var cannon_balls = [cannon_ball_prefab.instantiate(), cannon_ball_prefab.instantiate()]
		for cannon_ball in cannon_balls:
			obstacle_preload.add_child(cannon_ball)
			cannon_ball.global_position = initial_position
		
		cannon_balls[0].get_node("Sprite2D").global_position.y = random.randf_range(cannon_balls[0].get_node("Sprite2D").global_position.y, cannon_balls[0].get_node("Sprite2D").global_position.y + available_space - minimum_stack_distance)
		cannon_balls[1].get_node("Sprite2D").global_position.y = cannon_balls[0].get_node("Sprite2D").global_position.y + minimum_stack_distance
		cannon_balls_stack.append_array(cannon_balls)
	elif random_num < 8 + (2 * speed_progression):
		var cannon_ball = cannon_ball_prefab.instantiate()
		obstacle_preload.add_child(cannon_ball)
		cannon_ball.global_position = initial_position
		
		var sprite2D = cannon_ball.get_node("Sprite2D")
		sprite2D.global_position.y = random.randf_range(sprite2D.global_position.y, sprite2D.global_position.y + available_space)
		cannon_balls_stack.append(cannon_ball)

func get_game_time():
	var hours = floori(float(game_time) / 3600)
	var minutes = floori(float(game_time - hours * 3600) / 60)
	var seconds = game_time - (hours * 3600) - (minutes * 60)
	var minutes_string = str(minutes)
	if minutes < 10 :
		minutes_string = "0" + str(minutes)
	var seconds_string = str(seconds)
	if seconds < 10 :
		seconds_string = "0" + str(seconds)
	return str(hours) + ":" + minutes_string + ":" + seconds_string

func end_game(gold, score):
	get_tree().paused = true
	death_screen.get_node("GameOverSound").start_sound()
	var values_node = death_screen.get_node("Panel/HBoxContainer/Values")
	values_node.get_node("Time").text = get_game_time()
	values_node.get_node("Score").text = str(score) + " "
	values_node.get_node("Gold").text = str(gold) + " "
	death_screen.visible = true
