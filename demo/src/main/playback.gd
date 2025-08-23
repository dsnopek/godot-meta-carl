extends Node3D

@onready var hmd_node: MeshInstance3D = %HMD
@onready var left_hand: XRNode3D = %LeftHand
@onready var right_hand: XRNode3D = %RightHand

@onready var left_hand_default_transform: Transform3D = left_hand.transform
@onready var right_hand_default_transform: Transform3D = right_hand.transform

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

	left_hand.visible = (enabled_poses & CARLInputSample.POSE_LEFT_WRIST) or (enabled_poses & CARLInputSample.POSE_LEFT_JOINTS)
	right_hand.visible = (enabled_poses & CARLInputSample.POSE_RIGHT_JOINTS) or (enabled_poses & CARLInputSample.POSE_RIGHT_JOINTS)

	var left_wrist_pose: Transform3D = p_input_sample.left_wrist_pose if (enabled_poses & CARLInputSample.POSE_LEFT_WRIST) else left_hand_default_transform
	var right_wrist_pose: Transform3D = p_input_sample.right_wrist_pose if (enabled_poses & CARLInputSample.POSE_RIGHT_WRIST) else right_hand_default_transform

	_play_hand_joints(left_hand_tracker, p_input_sample.left_hand_joint_poses, left_wrist_pose)
	_play_hand_joints(right_hand_tracker, p_input_sample.right_hand_joint_poses, right_wrist_pose)

#	if enabled_poses & CARLInputSample.POSE_LEFT_WRIST:
#		left_hand_tracker.set_pose("default", p_input_sample.left_wrist_pose, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
#	else:
#		#left_hand_tracker.set_pose("default", left_hand_default_transform, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
#		left_hand_tracker.set_pose("default", Transform3D(), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
#		left_hand.transform = left_hand_default_transform
#
#	if enabled_poses & CARLInputSample.POSE_RIGHT_WRIST:
#		right_hand_tracker.set_pose("default", p_input_sample.right_wrist_pose, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
#	else:
#		#right_hand_tracker.set_pose("default", right_hand_default_transform, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
#		right_hand_tracker.set_pose("default", Transform3D(), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
#		right_hand.transform = right_hand_default_transform


func _play_hand_joints(p_tracker: XRHandTracker, p_joint_transforms: Array[Transform3D], p_wrist_pose: Transform3D) -> void:
	p_tracker.set_pose("default", p_wrist_pose, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	p_tracker.has_tracking_data = true

	var valid_flags: int = XRHandTracker.HAND_JOINT_FLAG_POSITION_TRACKED | XRHandTracker.HAND_JOINT_FLAG_POSITION_VALID | XRHandTracker.HAND_JOINT_FLAG_ORIENTATION_TRACKED | XRHandTracker.HAND_JOINT_FLAG_ORIENTATION_VALID

	var carl_joint := 0
	for godot_joint in range(XRHandTracker.HAND_JOINT_THUMB_METACARPAL, XRHandTracker.HAND_JOINT_MAX):
		if godot_joint == XRHandTracker.HAND_JOINT_INDEX_FINGER_METACARPAL or godot_joint == XRHandTracker.HAND_JOINT_MIDDLE_FINGER_METACARPAL or godot_joint == XRHandTracker.HAND_JOINT_RING_FINGER_METACARPAL:
			continue

		#p_tracker.set_hand_joint_transform(godot_joint, p_joint_transforms[carl_joint])
		#p_tracker.set_hand_joint_transform(godot_joint, p_joint_transforms[carl_joint] * p_wrist_pose)
		p_tracker.set_hand_joint_transform(godot_joint, p_wrist_pose * p_joint_transforms[carl_joint])
		p_tracker.set_hand_joint_flags(godot_joint, valid_flags)

		carl_joint += 1

	for godot_joint in [XRHandTracker.HAND_JOINT_PALM, XRHandTracker.HAND_JOINT_WRIST]:
		p_tracker.set_hand_joint_transform(godot_joint, p_wrist_pose)
		p_tracker.set_hand_joint_flags(godot_joint, valid_flags)
