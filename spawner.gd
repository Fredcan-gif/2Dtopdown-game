extends Node2D

@onready var main = get_parent()
var zombie_scene := preload("res://zombie.tscn")
var spawn_points := []

# Wave Management
var current_wave = 1
var zombies_to_spawn = 0
var zombies_alive = 0
@onready var spawn_timer = $Timer

func _ready():
	for i in get_children():
		if i is Marker2D:
			spawn_points.append(i)
	
	# Start the first wave after a short delay
	await get_tree().create_timer(1.0).timeout
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
	var zombie = zombie_scene.instantiate()
	
	# Set stats BEFORE adding to scene
	zombie.max_health = 100 + (current_wave * 20)
	zombie.health = zombie.max_health
	zombie.move_speed = 150 + (current_wave * 10)
	
	# Connect the zombie's 'died' signal to this script
	zombie.died.connect(_on_zombie_died)
	
	zombie.position = spawn.position
	main.add_child(zombie)

func _on_zombie_died():
	zombies_alive -= 1
	update_hud()
	
	if zombies_alive <= 0:
		current_wave += 1
		# 3-second breather between waves
		await get_tree().create_timer(3.0).timeout 
		start_wave()

func update_hud():
	# This calls the update_display function on every node in the "hud" group
	get_tree().call_group("hud", "update_display", current_wave, zombies_alive)
