extends CharacterBody2D


const SPEED = 300.0
const BASE_JUMP_VELOCITY = -442.7189

const MAX_JUMP_HEIGHT = 450
const MIN_JUMP_HEIGHT = 100

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var time_for_fast_jump = 0.25
var timer_wait_time = 2
@onready var timer1 = $Timer1

func _ready():
	timer1.wait_time = timer_wait_time

func _physics_process(delta):
	print(timer1.get_wait_time() - timer1.get_time_left())
	
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("Jump 1"):
		timer1.start()
	
	if Input.is_action_just_released("Jump 1") and can_jump():
		var hold_time = timer1.get_wait_time() - timer1.get_time_left()
		if hold_time <= time_for_fast_jump:
			velocity.y = BASE_JUMP_VELOCITY
		else:
			var height = (hold_time - time_for_fast_jump) / (timer1.get_wait_time() - time_for_fast_jump) * (MAX_JUMP_HEIGHT - MIN_JUMP_HEIGHT) + MIN_JUMP_HEIGHT
			velocity.y = sqrt(2*height/gravity) * -gravity
		timer1.stop()
	
	move_and_slide()

func can_jump():
	var groundCheck = $GroundCheck
	if groundCheck.has_overlapping_bodies():
		return true
	return false

func on_timer1_timeout():
	timer1.stop()
