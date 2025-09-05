extends VBoxContainer

func _show_screen(_info: Dictionary) -> void:
	for checkbox in %ActionTypeContainer.find_children("*", "CheckBox"):
		checkbox.button_pressed = false


func _on_cancel_button_pressed() -> void:
	get_parent().show_screen("DefinitionScreen")


func _on_new_button_pressed() -> void:
	var action_type: CARLDefinition.ActionType

	if %LeftHandShapeField.button_pressed:
		action_type = CARLDefinition.ACTION_LEFT_HAND_SHAPE
	elif %RightHandShapeField.button_pressed:
		action_type = CARLDefinition.ACTION_RIGHT_HAND_SHAPE
	elif %LeftHandPoseField.button_pressed:
		action_type = CARLDefinition.ACTION_LEFT_HAND_POSE
	elif %RightHandPoseField.button_pressed:
		action_type = CARLDefinition.ACTION_RIGHT_HAND_POSE
	elif %LeftHandTrajectoryField.button_pressed:
		action_type = CARLDefinition.ACTION_LEFT_WRIST_TRAJECTORY
	elif %RightHandTrajectoryField.button_pressed:
		action_type = CARLDefinition.ACTION_RIGHT_WRIST_TRAJECTORY
	elif %LeftHandGesture.button_pressed:
		action_type = CARLDefinition.ACTION_LEFT_HAND_GESTURE
	elif %RightHandGestureField.button_pressed:
		action_type = CARLDefinition.ACTION_RIGHT_HAND_GESTURE
	elif %TwoHandedGesture.button_pressed:
		action_type = CARLDefinition.ACTION_TWO_HAND_GESTURE

	var new_definition := CARLDefinition.new()
	new_definition.action_type = action_type
	GameState.current_definition = new_definition

	get_parent().show_screen("DefinitionScreen")
