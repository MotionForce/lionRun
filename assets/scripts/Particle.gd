extends Node2D

func _ready():
	get_node("CPUParticles2D").emitting = true

func _on_cpu_particles_2d_finished():
	self.queue_free()
