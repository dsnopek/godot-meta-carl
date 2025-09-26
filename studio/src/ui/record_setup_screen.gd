extends VBoxContainer

# @todo Swap the order of the Record and Cancel buttons depending on DisplayServer.get_swap_cancel_ok()

var _example_type: GameState.ExampleType

func _show_screen(p_info: Dictionary) -> void:
	_example_type = p_info.get('example_type', GameState.ExampleType.EXAMPLE)

	var action_type: CARLDefinition.ActionType = GameState.current_definition.action_type
	var enabled_poses: int = 0

	match action_type:
		CARLDefinition.ACTION_LEFT_HAND_SHAPE:
			enabled_poses = CARLInputSample.POSE_LEFT_JOINTS | CARLInputSample.POSE_LEFT_WRIST
		CARLDefinition.ACTION_RIGHT_HAND_SHAPE:
			enabled_poses = CARLInputSample.POSE_RIGHT_JOINTS | CARLInputSample.POSE_RIGHT_WRIST
		CARLDefinition.ACTION_LEFT_HAND_POSE:
			enabled_poses = CARLInputSample.POSE_LEFT_JOINTS | CARLInputSample.POSE_LEFT_WRIST | CARLInputSample.POSE_HMD
		CARLDefinition.ACTION_RIGHT_HAND_POSE:
			enabled_poses = CARLInputSample.POSE_RIGHT_JOINTS | CARLInputSample.POSE_RIGHT_WRIST | CARLInputSample.POSE_HMD
		CARLDefinition.ACTION_LEFT_WRIST_TRAJECTORY:
			enabled_poses = CARLInputSample.POSE_LEFT_WRIST | CARLInputSample.POSE_HMD
		CARLDefinition.ACTION_RIGHT_WRIST_TRAJECTORY:
			enabled_poses = CARLInputSample.POSE_RIGHT_WRIST | CARLInputSample.POSE_HMD
		CARLDefinition.ACTION_LEFT_HAND_GESTURE:
			enabled_poses = CARLInputSample.POSE_LEFT_JOINTS | CARLInputSample.POSE_LEFT_WRIST | CARLInputSample.POSE_HMD
		CARLDefinition.ACTION_RIGHT_HAND_GESTURE:
			enabled_poses = CARLInputSample.POSE_RIGHT_JOINTS | CARLInputSample.POSE_RIGHT_WRIST | CARLInputSample.POSE_HMD
		CARLDefinition.ACTION_TWO_HAND_GESTURE:
			enabled_poses = CARLInputSample.POSE_LEFT_JOINTS | CARLInputSample.POSE_LEFT_WRIST | \
							CARLInputSample.POSE_RIGHT_JOINTS | CARLInputSample.POSE_RIGHT_WRIST | \
							CARLInputSample.POSE_HMD

	%LeftWristPoseField.button_pressed = enabled_poses & CARLInputSample.POSE_LEFT_WRIST
	%RightWristPoseField.button_pressed = enabled_poses & CARLInputSample.POSE_RIGHT_WRIST
	%LeftJointPosesField.button_pressed = enabled_poses & CARLInputSample.POSE_LEFT_JOINTS
	%RightJointPosesField.button_pressed = enabled_poses & CARLInputSample.POSE_RIGHT_JOINTS
	%HMDPoseField.button_pressed = enabled_poses & CARLInputSample.POSE_HMD


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
		max_seconds = float(%MaxLengthField.value),
		delay = float(%DelayStartField.value),
		enabled_poses = enabled_poses,
	}

	get_parent().show_screen("RecordScreen", info)


func _on_cancel_button_pressed() -> void:
	get_parent().show_screen("DefinitionScreen")
