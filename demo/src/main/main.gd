extends Node3D

var recorder: CARLRecorder
var recording_poses: int
var recording_start: int

var current_recording: CARLRecording

func _ready() -> void:
	recorder = CARLRecorder.new()


func _process(_delta: float) -> void:
	if recorder.is_recording():
		record_input_sample()


func record_input_sample() -> void:
	var hmd_tracker: XRPositionalTracker = XRServer.get_tracker('head')
	var left_hand: XRHandTracker = XRServer.get_tracker('/user/hand_tracker/left')
	var right_hand: XRHandTracker = XRServer.get_tracker('/user/hand_tracker/right')

	var input_sample := CARLInputSample.new()
	input_sample.enabled_poses = recording_poses
	input_sample.timestamp = float(Time.get_ticks_usec() - recording_start) / 1000000.0

	if hmd_tracker:
		input_sample.hmd_pose = hmd_tracker.get_pose('default').transform

	if left_hand:
		input_sample.populate_from_hand_tracker(left_hand)

	if right_hand:
		input_sample.populate_from_hand_tracker(right_hand)

	recorder.record_input_sample(input_sample)


func _on_ui_record_start(p_info: Dictionary) -> void:
	recorder.start_recording(p_info['max_seconds'])
	recording_poses = p_info['enabled_poses']
	recording_start = Time.get_ticks_usec()
	record_input_sample()


func _on_ui_record_stop() -> void:
	current_recording = recorder.finish_recording()

	print(current_recording.serialize())
