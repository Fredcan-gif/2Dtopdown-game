extends Node2D

@onready var main = get_node("/root/Node2D")
var zombie_scene := preload("res://zombie.tscn")
var spawn_points := []

func _ready():
	for i in get_children():
		if i is Marker2D:
			spawn_points.append(i)
			

func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
		
	if spawn_points.size() == 0:
		return
		
	# Selects a random spawn point using arrays
	var spawn = spawn_points[randi() % spawn_points.size()]
	
	# This spawns the enemy
	var zombie = zombie_scene.instantiate()
	zombie.position = spawn.position
	main.add_child(zombie)
