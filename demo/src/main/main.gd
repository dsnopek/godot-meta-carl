extends Node3D

const Playback = preload("res://src/main/playback.gd")

@onready var playback: Playback = %Playback


func _ready() -> void:
	GameState.set_play_input_sample_callback(playback.play_input_sample)


func _on_ui_screen_shown(p_screen_control: Control) -> void:
	if p_screen_control.name == 'DefinitionScreen':
		if playback:
			playback.visible = true


func _on_ui_screen_hidden(p_screen_control: Control) -> void:
	if p_screen_control.name == 'DefinitionScreen':
		if playback:
			playback.visible = false


func _on_start_xr_focus_gained() -> void:
	get_tree().set_group("hand", "visible", true)


func _on_start_xr_focus_lost() -> void:
	get_tree().set_group("hand", "visible", false)
