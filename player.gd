extends CharacterBody2D

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var camera = $Camera2D
@onready var ammo_label = $AmmoLabel
@onready var health_bar_ui: TextureProgressBar = get_tree().get_first_node_in_group("player_hud")
@onready var tracer = $Tracer

@export var move_speed = 200
@export var max_health = 100
@export var gun_damage = 50
@export var fire_rate = 0.8
@export var regen_delay = 5.0 # seconds before HP regens
@export var regen_speed = 3.0 # HP given during regen

# --- Ammo Variables ---
@export var max_ammo = 8
@export var reload_time = 1.9
var current_ammo = 8
var is_reloading = false
var can_fire = true

var health = 100
var time_since_last_hit = 0.0
var dead = false
var can_take_damage = true

@onready var footstep_timer = $FootstepTimer
var is_left_foot = true
@onready var step_left = $StepLeft
@onready var step_right = $StepRight
@onready var step_middle = $StepMiddle

func _ready():
	health = max_health
	current_ammo = max_ammo
	update_ammo_ui()
	
	if health_bar_ui:
		health_bar_ui.max_value = max_health
		health_bar_ui.value = health

func _process(delta): # Changed _delta to delta here
	if Input.is_action_just_pressed("restart"):
		restart()
	
	if dead: return
		
	global_rotation = global_position.direction_to(get_global_mouse_position()).angle() + PI/2.0
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	if Input.is_action_just_pressed("reload") and current_ammo < max_ammo:
		reload()
		
	# --- Health Regen Logic ---
	if health < max_health:
		time_since_last_hit += delta # Now 'delta' is recognized
		if time_since_last_hit >= regen_delay:
			# Increment health, but don't exceed max
			health = min(health + (regen_speed * delta), max_health)
			if health_bar_ui:
				health_bar_ui.value = health

func _physics_process(_delta):
	if dead: return
	var move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = move_dir * move_speed
	move_and_slide()
	
	# --- FIX: Positioning UI above player correctly ---
	# We get the minimum size to ensure we know how wide the text currently is
	var text_width = ammo_label.get_combined_minimum_size().x
	ammo_label.global_position = global_position + Vector2(-text_width / 2, -50)
	
	if velocity.length() > 0 and footstep_timer.is_stopped():
		play_footstep() # Calls the Left/Right logic from Step 1
		footstep_timer.start(0.4)

func shoot():
	if is_reloading or dead or !can_fire: return
	if current_ammo <= 0:
		reload()
		return

	can_fire = false 
	current_ammo -= 1
	update_ammo_ui()
	apply_shake(15.0)
	
	# --- MUZZLE LIGHT LOGIC ---
	$MuzzleFlash.show()
	$MuzzleFlash/PointLight2D.enabled = true # Turn on the light
	
	$MuzzleFlash/Timer.start() # This timer should handle hiding the flash
	$ShootSound.play()

	# --- SHOTGUN SPREAD LOGIC ---
	var spread_angles = [-15, 0, 15]
	var max_range = 300
	
	for angle in spread_angles:
		var angle_rad = deg_to_rad(angle)
		var direction = Vector2.UP.rotated(global_rotation + angle_rad)
		ray_cast_2d.target_position = Vector2(0, -max_range).rotated(angle_rad)
		ray_cast_2d.force_raycast_update()
		
		var end_point = ray_cast_2d.global_position + direction * max_range
		if ray_cast_2d.is_colliding():
			var target = ray_cast_2d.get_collider()
			end_point = ray_cast_2d.get_collision_point()
			if target.has_method("take_damage"):
				# gun_damage is the health lost
				# direction is the pellet's travel direction
				# 400 is the 'strength' of the pushback per pellet
				target.take_damage(gun_damage, direction, 350.0)
		
		create_tracer(ray_cast_2d.global_position, end_point)

	# --- PUMP LOGIC ---
	# Wait a split second after the bang, then play pump sound
	await get_tree().create_timer(0.2).timeout
	if !dead and !is_reloading: 
		$PumpSound.play()
	
	# Wait for the rest of the fire_rate before allowing another shot
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func create_tracer(start, end):
	var new_tracer = tracer.duplicate() # Create a copy of our template
	get_tree().current_scene.add_child(new_tracer)
	new_tracer.show()
	
	# Set the points for the Line2D (Global coordinates)
	new_tracer.points = [new_tracer.to_local(start), new_tracer.to_local(end)]
	
	# Fade out and delete the tracer
	var tween = create_tween()
	tween.tween_property(new_tracer, "modulate:a", 0.0, 0.1) # 0.1 seconds fade
	tween.tween_callback(new_tracer.queue_free)

func reload():
	if is_reloading or dead: return
	is_reloading = true
	
	# 1. Play the main reload sound (stuffing shells)
	$ReloadSound.play()
	
	ammo_label.text = "RELOADING..."
	ammo_label.modulate = Color.YELLOW
	
	# Wait for the reload time
	await get_tree().create_timer(reload_time).timeout
	
	# 2. After stuffing shells, play the Pump sound to "chamber" the round
	$PumpSound.play()
	
	current_ammo = max_ammo
	ammo_label.modulate = Color.WHITE
	update_ammo_ui()
	ammo_label.reset_size()
	is_reloading = false
	can_fire = true # Ensure they can fire immediately after reloading

func update_ammo_ui():
	ammo_label.text = str(current_ammo) + " / " + str(max_ammo)
	
	# Turn text red when low on ammo
	if current_ammo <= 2:
		ammo_label.modulate = Color.RED
	else:
		ammo_label.modulate = Color.WHITE

func apply_shake(strength: float):
	var initial_offset = camera.offset
	for i in range(4):
		camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		await get_tree().create_timer(0.02).timeout
	camera.offset = initial_offset

func take_damage(amount):
	if dead or !can_take_damage: return
	
	health -= amount
	time_since_last_hit = 0.0 # Reset the regen timer!
	
	if health_bar_ui:
		health_bar_ui.value = health
	if health <= 0:
		kill()
		return
	
	can_take_damage = false
	modulate = Color(10, 1, 1) 
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1)
	can_take_damage = true

func kill():
	if dead: return
	dead = true
	ammo_label.hide()
	$DeathSound.play(1.26)
	$Graphics/Dead.show()
	$Graphics/BloodSplatter.show()
	$Graphics/Alive.hide()
	$CanvasLayer/DeathScreen.show()
	z_index = -1

func restart():
	get_tree().reload_current_scene()

func play_footstep():
	# Generate a random number: 0, 1, or 2
	var random_foot = randi() % 3
	
	if random_foot == 0:
		step_left.pitch_scale = randf_range(0.9, 1.1)
		step_left.play()
	elif random_foot == 1:
		step_right.pitch_scale = randf_range(0.9, 1.1)
		step_right.play()
	else:
		# This handles the '2' case
		step_middle.pitch_scale = randf_range(0.9, 1.1)
		step_middle.play()
