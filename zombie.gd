extends CharacterBody2D

signal died

@export var max_health = 100
@onready var health_bar = $ProgressBar
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D # Add this
@onready var player = get_tree().get_first_node_in_group("player")

var health = max_health
var dead = false
var knockback_velocity = Vector2.ZERO 

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@export var move_speed = 150

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.hide()
	
	# Wait for the first frame so the NavigationServer is ready
	set_physics_process(false)
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(_delta):
	if dead or !player or player.dead: return
	
	# 1. Update the goal
	nav_agent.target_position = player.global_position
	
	# 2. Movement Logic
	var dir_to_move = Vector2.ZERO 
	if not nav_agent.is_target_reached():
		var next_path_pos = nav_agent.get_next_path_position()
		dir_to_move = global_position.direction_to(next_path_pos)
		velocity = (dir_to_move * move_speed) + knockback_velocity
	else:
		velocity = Vector2.ZERO + knockback_velocity

	knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
	move_and_slide()
	
	# 3. FIXED Rotation Logic
	var dist_to_player = global_position.distance_to(player.global_position)
	# Increased attack range to 100 to ensure they see you before they hit the wall
	var attack_range = 100.0 
	
	# If close, prioritize looking at player OVER looking at the path
	if dist_to_player <= attack_range:
		var look_at_player = global_position.direction_to(player.global_position).angle() + PI/2.0
		global_rotation = lerp_angle(global_rotation, look_at_player, 0.2)
	elif dir_to_move != Vector2.ZERO:
		# Only look at the path if we aren't close enough to bite
		var target_angle = dir_to_move.angle() + PI/2.0
		global_rotation = lerp_angle(global_rotation, target_angle, 0.1)

	# 4. Attack Logic (Stays the same)
	if ray_cast_2d.is_colliding():
		var collider = ray_cast_2d.get_collider()
		if collider == player:
			player.take_damage(10)
	
	health_bar.global_position = global_position + Vector2(-20, -40)

func take_damage(amount, impact_dir := Vector2.ZERO, force := 0.0):
	if dead: return
	health -= amount
	health_bar.value = health
	health_bar.show()
	knockback_velocity += impact_dir * force
	modulate = Color(10, 10, 10) 
	await get_tree().create_timer(0.05).timeout
	modulate = Color(1, 1, 1)
	if health <= 0: kill()

func kill():
	if dead: return
	dead = true
	died.emit()
	$DeathSound.play()
	$Graphics/Dead.show()
	$Graphics/BloodSplatter.show()
	$Graphics/Alive.hide()
	health_bar.hide() 
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	z_index = -1
