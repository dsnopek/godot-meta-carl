extends Node3D

const Playback = preload("res://src/main/playback.gd")

@onready var playback: Playback = %Playback


func _ready() -> void:
	GameState.set_play_input_sample_callback(playback.play_input_sample)
