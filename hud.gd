extends CanvasLayer

@onready var wave_label = $VBoxContainer/WaveLabel
@onready var count_label = $VBoxContainer/CountLabel

# This function is called by the Spawner via 'call_group'
func update_display(wave, remaining):
	wave_label.text = "WAVE: " + str(wave)
	count_label.text = "ZOMBIES REMAINING: " + str(remaining)
