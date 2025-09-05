extends Node3D

const Playback = preload("res://src/main/playback.gd")

@onready var playback: Playback = %Playback

var has_xr_focus := false


func _ready() -> void:
	GameState.set_play_input_sample_callback(playback.play_input_sample)
	update_hand_tracking_message(false)


func update_hand_tracking_message(p_wait: bool = true) -> void:
	if p_wait:
		# Wait a moment so that all the events happen and flags get updated.
		await get_tree().create_timer(0.1).timeout
	%HandTrackingMessage.visible = has_xr_focus and not %LeftHand.get_has_tracking_data() and not %RightHand.get_has_tracking_data()


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
	has_xr_focus = true
	update_hand_tracking_message()


func _on_start_xr_focus_lost() -> void:
	get_tree().set_group("hand", "visible", false)
	has_xr_focus = false
	update_hand_tracking_message()


func _on_hand_tracking_changed(_tracking: bool) -> void:
	update_hand_tracking_message()
