extends Node

enum ExampleType {
	EXAMPLE,
	COUNTER_EXAMPLE,
}

var current_definition: CARLDefinition:
	set(v):
		if current_example:
			current_example = null
		if current_definition != v:
			current_definition = v
			current_definition_changed.emit(v)

var current_example: CARLExample:
	set(v):
		if current_example != v:
			current_example = v
			current_example_changed.emit(v)

signal current_definition_changed (definiton: CARLDefinition)
signal current_example_changed (example: CARLExample)
signal input_sample_played (input_sample: CARLInputSample)
signal example_added (example: CARLExample, type: ExampleType)

var _play_cb: Callable

var _prev_left_data_valid := false
var _prev_left_wrist_pose: Transform3D
var _prev_left_joint_poses: Array[Transform3D]

var _prev_right_data_valid := false
var _prev_right_wrist_pose: Transform3D
var _prev_right_joint_poses: Array[Transform3D]


func capture_input_sample() -> CARLInputSample:
	var hmd_tracker: XRPositionalTracker = XRServer.get_tracker('head')
	var left_hand: XRHandTracker = XRServer.get_tracker('/user/hand_tracker/left')
	var right_hand: XRHandTracker = XRServer.get_tracker('/user/hand_tracker/right')

	var input_sample := CARLInputSample.new()

	if hmd_tracker:
		input_sample.hmd_pose = hmd_tracker.get_pose('default').transform
	else:
		return null

	if left_hand and left_hand.has_tracking_data:
		input_sample.populate_from_hand_tracker(left_hand)

		_prev_left_wrist_pose = input_sample.left_wrist_pose
		_prev_left_joint_poses = input_sample.left_hand_joint_poses.duplicate()
		_prev_left_data_valid = true
	else:
		if not _prev_left_data_valid:
			return null
		input_sample.left_wrist_pose = _prev_left_wrist_pose
		input_sample.left_hand_joint_poses = _prev_left_joint_poses

	if right_hand and right_hand.has_tracking_data:
		input_sample.populate_from_hand_tracker(right_hand)

		_prev_right_wrist_pose = input_sample.right_wrist_pose
		_prev_right_joint_poses = input_sample.right_hand_joint_poses.duplicate()
		_prev_right_data_valid = true
	else:
		if not _prev_right_data_valid:
			return null
		input_sample.right_wrist_pose = _prev_right_wrist_pose
		input_sample.right_hand_joint_poses = _prev_right_joint_poses

	return input_sample


func set_play_input_sample_callback(p_callable: Callable) -> void:
	_play_cb = p_callable


func play_input_sample(p_input_sample: CARLInputSample) -> void:
	if not _play_cb.is_valid():
		#push_warning("GameState.play_input_sample() called but we have no valid callback")
		return

	_play_cb.call(p_input_sample)
	input_sample_played.emit(p_input_sample)


func add_example(p_example: CARLExample, p_type: ExampleType) -> void:
	assert(current_definition != null)

	if p_type == ExampleType.EXAMPLE:
		current_definition.add_example(p_example)
	else:
		current_definition.add_counter_example(p_example)

	example_added.emit(p_example, p_type)
