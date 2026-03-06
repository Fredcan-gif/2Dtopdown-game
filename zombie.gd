# Zombie.gd
extends CharacterBody2D

signal died # Let the manager know we're gone

@export var max_health = 100
@onready var health_bar = $ProgressBar
var health = max_health
var dead = false

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@export var move_speed = 150
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	# Combined logic: initialize stats AND hide the bar
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.hide()

func _physics_process(_delta):
	# Safety check for player (in case they are deleted/null)
	if dead or !player or player.dead: return
	
	var dir_to_player = global_position.direction_to(player.global_position)
	velocity = dir_to_player * move_speed
	move_and_slide()
	global_rotation = dir_to_player.angle() + PI/2.0
	
	if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider() == player:
		player.take_damage(10)
		
	# Health Bar positioning (requires "Top Level" enabled in Inspector)
	health_bar.global_position = global_position + Vector2(-20, -40)


func take_damage(amount):
	if dead: return
	health -= amount
	health_bar.value = health
	health_bar.show() # Reveal bar on first hit
	
	# Optional: Visual hit flash
	modulate = Color(10, 10, 10) 
	await get_tree().create_timer(0.05).timeout
	modulate = Color(1, 1, 1)

	if health <= 0:
		kill()

func kill():
	if dead: return
	dead = true
	died.emit()
	$DeathSound.play()
	$Graphics/Dead.show()
	$Graphics/BloodSplatter.show()
	$Graphics/Alive.hide()
	health_bar.hide() # Hide health bar on death
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	z_index = -1
