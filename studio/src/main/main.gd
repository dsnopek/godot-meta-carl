extends Node3D

const Playback = preload("res://src/main/playback.gd")

const STORAGE_PERMISSIONS = [
	"android.permission.READ_EXTERNAL_STORAGE",
	"android.permission.WRITE_EXTERNAL_STORAGE",
	"android.permission.MANAGE_EXTERNAL_STORAGE",
]

@onready var playback: Playback = %Playback


func _ready() -> void:
	GameState.set_play_input_sample_callback(playback.play_input_sample)

	# Needed to access files in other projects.
	for perm in STORAGE_PERMISSIONS:
		OS.request_permission(perm)


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
