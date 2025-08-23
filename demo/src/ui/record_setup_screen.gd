extends VBoxContainer

# @todo Swap the order of the Record and Cancel buttons depending on DisplayServer.get_swap_cancel_ok()

var _example_type: GameState.ExampleType

func _show_screen(p_info: Dictionary) -> void:
	_example_type = p_info.get('example_type', GameState.ExampleType.EXAMPLE)


func _on_record_button_pressed() -> void:
	var enabled_poses: int = 0

	if %LeftWristPoseField.button_pressed:
		enabled_poses |= CARLInputSample.POSE_LEFT_WRIST
	if %RightWristPoseField.button_pressed:
		enabled_poses |= CARLInputSample.POSE_RIGHT_WRIST
	if %LeftJointPosesField.button_pressed:
		enabled_poses |= CARLInputSample.POSE_LEFT_JOINTS
	if %RightJointPosesField.button_pressed:
		enabled_poses |= CARLInputSample.POSE_RIGHT_JOINTS
	if %HMDPoseField.button_pressed:
		enabled_poses |= CARLInputSample.POSE_HMD

	var info := {
		example_type = _example_type,
		max_seconds = int(%MaxLengthField.value),
		delay = int(%DelayStartField.value),
		enabled_poses = enabled_poses,
	}

	get_parent().show_screen("RecordScreen", info)


func _on_cancel_button_pressed() -> void:
	# @todo Return to definition screen
	pass
