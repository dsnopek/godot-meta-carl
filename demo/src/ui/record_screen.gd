extends VBoxContainer

@onready var label: Label = %Label
@onready var stop_button: Button = %StopButton
@onready var timer: Timer = %Timer

var _record_info: Dictionary
var _delay: int

var _recorder := CARLRecorder.new()
var _recording_start: int

func _ready() -> void:
	set_process(false)

func _show_screen(p_info: Dictionary) -> void:
	_record_info = p_info

	_delay = int(_record_info['delay'])
	_record_info.erase('delay')

	update_label_text()

	if _delay > 0:
		timer.start()
	else:
		start_recording()


func update_label_text() -> void:
	if _delay > 0:
		label.text = "Recording starting in %s..." % _delay
		stop_button.text = "Cancel"
	else:
		label.text = "Recording..."
		stop_button.text = "Stop"


func _on_timer_timeout() -> void:
	_delay -= 1
	update_label_text()
	if _delay == 0:
		timer.stop()
		start_recording()


func start_recording() -> void:
	_recorder.start_recording(_record_info['max_seconds'])
	_recording_start = Time.get_ticks_usec()
	record_input_sample(0.0)
	set_process(true)


func _process(_delta: float) -> void:
	if _recorder.is_recording():
		var timestamp: float = float(Time.get_ticks_usec() - _recording_start) / 1000000.0

		if timestamp >= _record_info['max_seconds']:
			stop_recording()
			return

		record_input_sample(timestamp)


func populate_from_tracker(p_input_sample: CARLInputSample, p_tracker: XRHandTracker) -> void:
	var hand: XRPositionalTracker.TrackerHand = p_tracker.hand

	var jts: Array[Transform3D] = p_input_sample.left_hand_joint_poses if hand == XRPositionalTracker.TRACKER_HAND_LEFT else p_input_sample.right_hand_joint_poses

	var ht: Transform3D = p_tracker.get_pose("default").transform
	var hti := ht.affine_inverse()

	var carl_joint := 0
	for godot_joint in range(XRHandTracker.HAND_JOINT_THUMB_METACARPAL, XRHandTracker.HAND_JOINT_MAX):
		if godot_joint == XRHandTracker.HAND_JOINT_INDEX_FINGER_METACARPAL or godot_joint == XRHandTracker.HAND_JOINT_MIDDLE_FINGER_METACARPAL or godot_joint == XRHandTracker.HAND_JOINT_RING_FINGER_METACARPAL:
			continue

		#jts[carl_joint] = p_tracker.get_hand_joint_transform(godot_joint)
		#jts[carl_joint] = p_tracker.get_hand_joint_transform(godot_joint) * hti
		jts[carl_joint] = hti * p_tracker.get_hand_joint_transform(godot_joint)

		carl_joint += 1

	if hand == XRPositionalTracker.TRACKER_HAND_LEFT:
		p_input_sample.left_wrist_pose = ht
		p_input_sample.left_hand_joint_poses = jts
	else:
		p_input_sample.right_wrist_pose = ht
		p_input_sample.right_hand_joint_poses = jts


func record_input_sample(p_timestamp: float) -> void:
	var hmd_tracker: XRPositionalTracker = XRServer.get_tracker('head')
	var left_hand: XRHandTracker = XRServer.get_tracker('/user/hand_tracker/left')
	var right_hand: XRHandTracker = XRServer.get_tracker('/user/hand_tracker/right')

	var input_sample := CARLInputSample.new()
	input_sample.enabled_poses = _record_info['enabled_poses']
	input_sample.timestamp = p_timestamp

	if hmd_tracker:
		input_sample.hmd_pose = hmd_tracker.get_pose('default').transform

	if left_hand:
		#input_sample.populate_from_hand_tracker(left_hand)
		populate_from_tracker(input_sample, left_hand)

	if right_hand:
		#input_sample.populate_from_hand_tracker(right_hand)
		populate_from_tracker(input_sample, right_hand)


	_recorder.record_input_sample(input_sample)


func stop_recording() -> void:
	if _recorder.is_recording():
		GameState.current_recording = _recorder.finish_recording()
		print(GameState.current_recording.serialize())

	set_process(false)
	get_parent().show_screen("DefinitionScreen", { play = true })


func _on_stop_button_pressed() -> void:
	stop_recording()
