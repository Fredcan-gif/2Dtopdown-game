extends Label

@export var flicker_chance = 0.05
@export var min_alpha = 0.2
@export var max_alpha = 1.0

func _process(_delta):
	# Most of the time, stay bright
	if randf() < flicker_chance:
		# Randomly dip the transparency (modulate:a)
		modulate.a = randf_range(min_alpha, max_alpha)
	else:
		# Smoothly return to full brightness
		modulate.a = lerp(modulate.a, 1.0, 0.2)
