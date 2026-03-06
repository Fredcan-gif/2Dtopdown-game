extends CharacterBody2D

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@export var move_speed = 200
@export var max_health = 100 # Renamed to max_health for clarity
@export var gun_damage = 50

var health = 100
var dead = false
var can_take_damage = true
@onready var health_bar_ui: TextureProgressBar = get_tree().get_first_node_in_group("player_hud")

func _ready():
	health = max_health
	if health_bar_ui:
		health_bar_ui.max_value = max_health
		health_bar_ui.value = health

func _process(delta):
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if Input.is_action_just_pressed("restart"):
		restart()
	if dead:
		return
		
	global_rotation = global_position.direction_to(get_global_mouse_position()).angle() + PI/2.0
	if Input.is_action_just_pressed("shoot"):
		shoot()
		
func _physics_process(delta):
	if dead:
		return
	var move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = move_dir * move_speed
	move_and_slide()
	
func kill():
	if dead:
		return
	dead = true
	$DeathSound.play()
	$Graphics/Dead.show()
	$Graphics/BloodSplatter.show()
	$Graphics/Alive.hide()
	$CanvasLayer/DeathScreen.show()
	z_index = -1

func take_damage(amount):
	if dead or !can_take_damage: 
		return
	
	health -= amount
	
	# Update the HUD Bar
	if health_bar_ui:
		health_bar_ui.value = health
	
	if health <= 0:
		kill()
		return # Stop further logic if dead

	# Invincibility frames logic
	can_take_damage = false
	# Optional: Visual feedback for being hit (flashing red)
	modulate = Color(10, 1, 1) 
	await get_tree().create_timer(0.5).timeout
	modulate = Color(1, 1, 1)
	can_take_damage = true
		
func shoot():
	$MuzzleFlash.show()
	$MuzzleFlash/Timer.start()
	$ShootSound.play()
	
	if ray_cast_2d.is_colliding():
		var target = ray_cast_2d.get_collider()
		if target.has_method("take_damage"):
			target.take_damage(gun_damage)
	
func restart():
	get_tree().reload_current_scene()
