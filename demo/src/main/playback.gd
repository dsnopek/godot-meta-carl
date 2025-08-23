extends Node3D

const DEFAULT_WRIST_HEIGHT := 1.2
const DEFAULT_WRIST_OFFSET := 0.2

@onready var hmd_node: MeshInstance3D = %HMD
@onready var left_hand: XRNode3D = %LeftHand
@onready var right_hand: XRNode3D = %RightHand

var left_hand_tracker: XRHandTracker
var right_hand_tracker: XRHandTracker

func _ready() -> void:
	left_hand_tracker = XRHandTracker.new()
	left_hand_tracker.name = '/playback/left_hand'
	left_hand_tracker.hand = XRPositionalTracker.TRACKER_HAND_LEFT
	XRServer.add_tracker(left_hand_tracker)

	right_hand_tracker = XRHandTracker.new()
	right_hand_tracker.name = '/playback/right_hand'
	right_hand_tracker.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	XRServer.add_tracker(right_hand_tracker)


func play_input_sample(p_input_sample: CARLInputSample) -> void:
	var enabled_poses := p_input_sample.enabled_poses

	if enabled_poses & CARLInputSample.POSE_HMD:
		hmd_node.visible = true
		hmd_node.transform = p_input_sample.hmd_pose
	else:
		hmd_node.visible = false

	left_hand.visible = enabled_poses & CARLInputSample.POSE_LEFT_WRIST or enabled_poses & CARLInputSample.POSE_LEFT_JOINTS
	right_hand.visible = enabled_poses & CARLInputSample.POSE_RIGHT_JOINTS or enabled_poses & CARLInputSample.POSE_RIGHT_JOINTS

	# @todo How to handle the wrist position?

	_play_hand_joints(left_hand_tracker, p_input_sample.left_hand_joint_poses)
	_play_hand_joints(right_hand_tracker, p_input_sample.right_hand_joint_poses)


func _play_hand_joints(p_tracker: XRHandTracker, p_joint_transforms: Array[Transform3D]) -> void:
	for joint in range(XRHandTracker.HAND_JOINT_MAX):
		p_tracker.set_hand_joint_transform(joint, p_joint_transforms[joint])
		p_tracker.set_hand_joint_flags(joint, XRHandTracker.HAND_JOINT_FLAG_POSITION_TRACKED | XRHandTracker.HAND_JOINT_FLAG_POSITION_VALID | XRHandTracker.HAND_JOINT_FLAG_ORIENTATION_TRACKED | XRHandTracker.HAND_JOINT_FLAG_ORIENTATION_VALID)
