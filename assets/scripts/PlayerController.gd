extends CharacterBody2D

const MAX_JUMP_HEIGHT = 325
const MIN_JUMP_HEIGHT = 105
const INITIAL_GOLD = 300

const INITIAL_COLLISION_COST = -100
const INITIAL_RING_REWARD = 100
const INITIAL_PATIENCE_THRESHOLD = 25

var gold = 300
var max_gold_acquired = 300

var gold_bonus_stack = 0
var collision_cost_stack = 0
var patience_stack = 0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var time_for_fast_jump = 0.25
var timer_wait_time = 1.25
@onready var timer1 = $Timer1
@onready var timer2 = $Timer2
@onready var animation = $AnimatedSprite2D
@onready var ground_particle = $GroundParticle/CPUParticles2D
var particle_parent

var score = 0
var hold_time = 0
var e_hold_time_1 = 0
var e_hold_time_2 = 0

var particle_prefab_path = load("res://assets/prefabs/Particle.tscn")

func _ready():
	particle_parent = get_parent().get_parent().get_node("Particules")
	gold = INITIAL_GOLD
	max_gold_acquired = INITIAL_GOLD
	timer1.wait_time = timer_wait_time
	timer2.wait_time = timer_wait_time

func _physics_process(delta):
	calculate_score()
	if not is_on_floor():
		velocity.y += gravity * delta
		animation.stop()
		ground_particle.emitting = false
	else:
		animation.play()
		ground_particle.emitting = true

	var press1 = Input.is_action_pressed("Jump 1") 
	var press2 = Input.is_action_pressed("Jump 2")

	if Input.is_action_just_pressed("Jump 1"):
		timer1.start()
	
	if Input.is_action_just_pressed("Jump 2"):
		timer2.start()
	
	if Input.is_action_just_released("Jump 1") and can_jump():
		hold_time = timer1.get_wait_time() - timer1.get_time_left()
		if hold_time <= time_for_fast_jump:
			velocity.y = sqrt(2*MIN_JUMP_HEIGHT/gravity) * -gravity
		else:
			var height = (hold_time - time_for_fast_jump) / (timer1.get_wait_time() - time_for_fast_jump) * (MAX_JUMP_HEIGHT - MIN_JUMP_HEIGHT) + MIN_JUMP_HEIGHT
			velocity.y = sqrt(2*height/gravity) * -gravity
		timer1.stop()
	
	if Input.is_action_just_released("Jump 2") and can_jump():
		hold_time = timer2.get_wait_time() - timer2.get_time_left()
		if hold_time <= time_for_fast_jump:
			velocity.y = sqrt(2*MIN_JUMP_HEIGHT/gravity) * -gravity
		else:
			var height = (hold_time - time_for_fast_jump) / (timer2.get_wait_time() - time_for_fast_jump) * (MAX_JUMP_HEIGHT - MIN_JUMP_HEIGHT) + MIN_JUMP_HEIGHT
			velocity.y = sqrt(2*height/gravity) * -gravity
		timer2.stop()
	
	e_hold_time_1 = timer1.get_wait_time() - timer1.get_time_left()
	e_hold_time_2 = timer2.get_wait_time() - timer2.get_time_left()

	if not press1:
		e_hold_time_1 = 0
	if not press2:
		e_hold_time_2 = 0
	
	move_and_slide()

func can_jump():
	var groundCheck = $GroundCheck
	if groundCheck.has_overlapping_bodies():
		return true
	return false

func on_timer1_timeout():
	timer1.stop()
func on_timer2_timeout():
	timer2.stop()

func on_obstacle_check_area_entered(area):
	if area.collision_layer == 2:
		on_general_collisision()
	if area.collision_layer == 4:
		on_ring_collision(area)

func on_general_collisision():
	play_obstacle_sound()
	collision_cost_stack += 1 * floor(1 + get_game_time() / 90)
	var gold_amount_change = calculate_collision_cost()
	change_gold_amount(gold_amount_change)
	spawn_hit_particles(gold_amount_change)

func on_ring_collision(area):
	play_ring_sound()
	area.get_parent().get_parent().add_to_group("Collided")
	gold_bonus_stack += 1
	patience_stack -= gold_bonus_stack - floor(get_speed_progression())
	if patience_stack < 0:
		patience_stack = 0
	collision_cost_stack -= 1 * floor(1 + get_game_time() / 180)
	if collision_cost_stack < 0:
		collision_cost_stack = 0
	var gold_amount_change = calculate_gold_reward()
	change_gold_amount(gold_amount_change)
	spawn_hit_particles(gold_amount_change)

func change_gold_amount(amount):
	gold += amount
	if gold > max_gold_acquired:
		max_gold_acquired = gold
	elif gold <= 0:
		on_player_reach_0_gold()

func on_player_reach_0_gold():
	get_parent().get_parent().gold_display.text = str(0)
	get_parent().get_parent().end_game(max_gold_acquired, score)

func on_queue_free_obstacle(obstacle):
	if obstacle.is_in_group("Ring") == false:
		return
	if obstacle.is_in_group("Collided") == true:
		return
	patience_stack += 1
	gold_bonus_stack -= 1 * floor(1 + get_game_time() / 90)
	if gold_bonus_stack < 0:
		patience_stack -= gold_bonus_stack * floor(get_game_time() / 180)
		gold_bonus_stack = 0

func calculate_gold_reward():
	var gold_reward = INITIAL_RING_REWARD * gold_bonus_stack
	return gold_reward

func calculate_collision_cost():
	var collision_cost = INITIAL_COLLISION_COST * collision_cost_stack
	if patience_stack >= float(INITIAL_PATIENCE_THRESHOLD) / (1 + (4 * get_speed_progression())):
		collision_cost -= INITIAL_COLLISION_COST * patience_stack
	return collision_cost

func get_speed_progression():
	return get_parent().get_parent().speed_progression
	
func get_game_time():
	return get_parent().get_parent().game_time

func obstacle_queued():
	return get_parent().get_parent().obstacle_queued

func play_ring_sound():
	var ring_audio = get_node("RingAudio")
	ring_audio.volume_db = randf_range(-5, 5)
	ring_audio.pitch_scale = randf_range(0.5, 1.5)
	ring_audio.play()

func play_obstacle_sound():
	var ring_audio = get_node("ObstacleAudio")
	ring_audio.volume_db = randf_range(-5, 5)
	ring_audio.pitch_scale = randf_range(0.5, 1.5)
	ring_audio.play()

func calculate_score():
	score = obstacle_queued() * 100
	score += max_gold_acquired

func spawn_hit_particles(amount):
	var particle = particle_prefab_path.instantiate()
	particle_parent.add_child(particle)
	particle.global_position = global_position
	var gradient_ramp = Gradient.new()
	if amount > 0:
		gradient_ramp = load("res://assets/particle/RingParticleColorRamp.tres")
	else:
		gradient_ramp = load("res://assets/particle/ObstacleParticleColorRamp.tres")
	particle.get_node("CPUParticles2D").set_color_ramp(gradient_ramp)
	particle.get_node("TextParticle/Label").text = str(amount)
