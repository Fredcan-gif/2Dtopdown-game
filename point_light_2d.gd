extends PointLight2D

@export var base_energy = 0.8
@export var flicker_intensity = 0.2

func _process(_delta):
	# Small jitters: keeps the light feeling "unstable"
	energy = base_energy + randf_range(-flicker_intensity, flicker_intensity)
	
	# Rare "Big Pop": The light almost goes out entirely
	if randf() < 0.005: 
		energy = 0.1
		await get_tree().create_timer(0.1).timeout
		energy = base_energy
