extends Node2D

@onready var main = get_parent()
# --- ADDED AUDIO REFERENCE ---
@onready var wave_incoming_sound = $WaveIncomingSound 

var zombie_scene := preload("res://zombie.tscn")
var boss_scene := preload("res://boss_zombie.tscn")
var spawn_points := []

# Wave Management
var current_wave = 1
var zombies_to_spawn = 0
var zombies_alive = 0
@onready var spawn_timer = $Timer
@export var damage = 20 # Default damage


func _ready():
	for i in get_children():
		if i is Marker2D:
			spawn_points.append(i)
	
	# Start the first wave after a short delay
	await get_tree().create_timer(1.0).timeout
	# Play sound for the very first wave
	if wave_incoming_sound: wave_incoming_sound.play() 
	start_wave()

func start_wave():
	zombies_to_spawn = 5 + (current_wave * 2)
	zombies_alive = zombies_to_spawn
	
	# Faster spawning as waves progress
	spawn_timer.wait_time = max(0.5, 2.0 - (current_wave * 0.1))
	
	update_hud()
	spawn_timer.start()

func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	
	# Stop spawning if player is dead or we hit the wave limit
	if player == null or player.dead or zombies_to_spawn <= 0:
		return
		
	if spawn_points.size() > 0:
		spawn_zombie()
		zombies_to_spawn -= 1

func spawn_zombie():
	var spawn = spawn_points[randi() % spawn_points.size()]
	var is_boss_wave = (current_wave % 3 == 0)
	
	# Decide which scene to use
	var scene_to_use = zombie_scene
	# If it's a boss wave and it's the very first zombie of that wave
	if is_boss_wave and zombies_to_spawn == (5 + (current_wave * 2)):
		scene_to_use = boss_scene
	
	var zombie = scene_to_use.instantiate()
	
	# --- Scaling Stats ---
	if scene_to_use == boss_scene:
		zombie.max_health = (100 + (current_wave * 20)) * 5
		zombie.damage = (10 + (current_wave * 5)) * 2
		zombie.move_speed = 120
		
		# Ensure the navigation agent knows it's a bit wider
		var agent = zombie.get_node("NavigationAgent2D")
		agent.radius = 25.0 
		agent.path_desired_distance = 30.0
	else:
		# Regular zombie stats
		zombie.max_health = 100 + (current_wave * 20)
		zombie.move_speed = 150 + (current_wave * 3)
		zombie.damage = 10 + (current_wave * 3)
	
	zombie.health = zombie.max_health
	zombie.died.connect(_on_zombie_died)
	zombie.position = spawn.position
	main.add_child(zombie)

func _on_zombie_died():
	zombies_alive -= 1
	update_hud()
	
	if zombies_alive <= 0:
		current_wave += 1
		await get_tree().create_timer(3.0).timeout 
		
		if wave_incoming_sound:
			wave_incoming_sound.pitch_scale = randf_range(0.85, 1.0)
			wave_incoming_sound.play()
			
		start_wave()

func update_hud():
	get_tree().call_group("hud", "update_display", current_wave, zombies_alive)
