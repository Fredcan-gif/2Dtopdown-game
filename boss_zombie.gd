extends CharacterBody2D

signal died

@export var max_health = 500 # Scaled up for Boss
@export var damage = 30     # Scaled up for Boss
@onready var health_bar = $ProgressBar
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var player = get_tree().get_first_node_in_group("player")

var health = max_health
var dead = false
var knockback_velocity = Vector2.ZERO 
var can_attack = true

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@export var move_speed = 100 # Bosses are usually slower and heavier
@onready var attack_timer = $AttackTimer
@onready var footstep_timer = $FootstepTimer
@onready var steps = [$StepLeft, $StepRight, $StepMiddle]
@onready var moan_timer = $MoanTimer
@onready var moan_sound = $MoanSound
@onready var slash_sound = $SlashSound
@onready var growl_player = $AttackGrowl

# You can use the same sounds, but we will pitch them down in code
var moan_sounds = [
	preload("res://assets/SFX/24bit/Vocal/Attack/zombie_massacre_vocal_attack_medium_03.wav"),
	preload("res://assets/SFX/24bit/Vocal/Attack/zombie_massacre_vocal_attack_medium_06.wav"),
	preload("res://assets/SFX/24bit/Vocal/Attack/zombie_massacre_vocal_attack_short_03.wav"),
	preload("res://assets/SFX/24bit/Vocal/Attack/zombie_massacre_vocal_attack_medium_11.wav")
]

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.hide()
	
	set_physics_process(false)
	await get_tree().physics_frame
	set_physics_process(true)

func _physics_process(_delta):
	if dead or !player or player.dead: return
	
	# --- BOSS FOOTSTEPS ---
	# We use a lower velocity check and a longer timer (0.7) for heavy thuds
	if velocity.length() > 10.0 and footstep_timer.is_stopped():
		play_heavy_thud_sound()
		footstep_timer.start(0.7)
	
	nav_agent.target_position = player.global_position
	
	var dir_to_move = Vector2.ZERO 
	if not nav_agent.is_target_reached():
		var next_path_pos = nav_agent.get_next_path_position()
		dir_to_move = global_position.direction_to(next_path_pos)
		velocity = (dir_to_move * move_speed) + knockback_velocity
	else:
		velocity = Vector2.ZERO + knockback_velocity

	knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
	move_and_slide()
	
	var dist_to_player = global_position.distance_to(player.global_position)
	var attack_range = 130.0 # Boss has a larger reach
	
	if dist_to_player <= attack_range:
		var look_at_player = global_position.direction_to(player.global_position).angle() + PI/2.0
		global_rotation = lerp_angle(global_rotation, look_at_player, 0.2)
	elif dir_to_move != Vector2.ZERO:
		var target_angle = dir_to_move.angle() + PI/2.0
		global_rotation = lerp_angle(global_rotation, target_angle, 0.1)
		
	if ray_cast_2d.is_colliding() and can_attack:
		var collider = ray_cast_2d.get_collider()
		if collider == player:
			perform_attack()
			
	health_bar.global_position = global_position + Vector2(-20, -60) # Positioned higher for big boss
	
func perform_attack():
	can_attack = false
	
	# 1. The Growl (Pitched DOWN for a roar effect)
	growl_player.pitch_scale = randf_range(0.5, 0.7)
	growl_player.volume_db = 2.0 
	growl_player.play()
	
	# 2. The Slash (Heavier impact sound)
	slash_sound.pitch_scale = randf_range(0.6, 0.8) 
	slash_sound.play()
	
	player.take_damage(damage)
	attack_timer.start()

func _on_attack_timer_timeout():
	can_attack = true

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
	
func play_heavy_thud_sound():
	var random_step = steps[randi() % steps.size()]
	
	# Boss footsteps are deep and slightly louder than regular zombies
	random_step.pitch_scale = randf_range(0.6, 0.8)
	random_step.volume_db = -5.0 
	random_step.play()

func _on_moan_timer_timeout() -> void:
	if dead: return
	
	moan_sound.stream = moan_sounds[randi() % moan_sounds.size()]
	
	# Boss moans are deep roars
	moan_sound.pitch_scale = randf_range(0.4, 0.6)
	moan_sound.volume_db = 0.0 
	moan_sound.play()
	
	# Boss moans less frequently (10-25 seconds)
	moan_timer.start(randf_range(10.0, 25.0))
