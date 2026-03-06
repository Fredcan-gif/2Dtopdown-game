
extends Node2D

@export var zombie_scene: PackedScene
@export var spawn_points: Array[Marker2D]

var current_wave = 1
var zombies_to_spawn = 5
var zombies_killed = 0
var active_zombies = 0

@onready var wave_label = %WaveLabel # Use Unique Names (%) for UI
@onready var count_label = %CountLabel
@onready var spawn_timer = $SpawnTimer

func _ready():
	start_wave()

func start_wave():
	zombies_killed = 0
	zombies_to_spawn = 5 + (current_wave * 2) # Example scaling
	active_zombies = 0
	update_ui()
	
	# Increase difficulty
	spawn_timer.wait_time = max(0.5, 2.0 - (current_wave * 0.1)) 
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if active_zombies < zombies_to_spawn:
		spawn_zombie()
	else:
		spawn_timer.stop()

func spawn_zombie():
	var zombie = zombie_scene.instantiate()
	# Scale zombie HP based on wave
	zombie.max_health = 100 + (current_wave * 20)
	zombie.health = zombie.max_health
	
	var spawn_pos = spawn_points.pick_random().global_position
	zombie.global_position = spawn_pos
	
	# Connect the signal via code
	zombie.died.connect(_on_zombie_died)
	
	get_parent().add_child(zombie)
	active_zombies += 1

func _on_zombie_died():
	zombies_killed += 1
	update_ui()
	if zombies_killed >= zombies_to_spawn:
		next_wave()

func next_wave():
	current_wave += 1
	# Give player a small breather
	await get_tree().create_timer(3.0).timeout
	start_wave()

func update_ui():
	wave_label.text = "Wave: " + str(current_wave)
	count_label.text = "Zombies Left: " + str(zombies_to_spawn - zombies_killed)
