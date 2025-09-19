extends Node3D

const JointDebugger = preload("res://src/main/joint_debugger.gd")

const DEBUG_JOINTS := false

@onready var hmd_node: MeshInstance3D = %HMD
@onready var left_hand: XRNode3D = %LeftHand
@onready var right_hand: XRNode3D = %RightHand

@onready var left_hand_default_transform: Transform3D = left_hand.transform
@onready var right_hand_default_transform: Transform3D = right_hand.transform

@onready var left_hand_mesh: Node3D = %LeftHandMesh
@onready var right_hand_mesh: Node3D = %RightHandMesh

@onready var left_hand_joint_debugger: JointDebugger = %LeftHandJointDebugger
@onready var right_hand_joint_debugger: JointDebugger = %RightHandJointDebugger

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

	if DEBUG_JOINTS:
		left_hand.tracker = ''
		right_hand.tracker = ''
		left_hand_mesh.visible = false
		right_hand_mesh.visible = false
	else:
		left_hand_joint_debugger.visible = false
		right_hand_joint_debugger.visible = false


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

	if DEBUG_JOINTS:
		left_hand.transform = left_wrist_pose
		right_hand.transform = right_wrist_pose
		left_hand_joint_debugger.update_joints(p_input_sample.left_hand_joint_poses)
		right_hand_joint_debugger.update_joints(p_input_sample.right_hand_joint_poses)
	else:
		_play_hand_tracker_joints(left_hand_tracker, p_input_sample.left_hand_joint_poses, left_wrist_pose)
		_play_hand_tracker_joints(right_hand_tracker, p_input_sample.right_hand_joint_poses, right_wrist_pose)


func _play_hand_tracker_joints(p_tracker: XRHandTracker, p_joint_transforms: Array[Transform3D], p_wrist_pose: Transform3D) -> void:
	var valid_flags: int = XRHandTracker.HAND_JOINT_FLAG_POSITION_TRACKED | XRHandTracker.HAND_JOINT_FLAG_POSITION_VALID | XRHandTracker.HAND_JOINT_FLAG_ORIENTATION_TRACKED | XRHandTracker.HAND_JOINT_FLAG_ORIENTATION_VALID

	var carl_joint := 1
	for godot_joint in range(XRHandTracker.HAND_JOINT_THUMB_METACARPAL, XRHandTracker.HAND_JOINT_MAX):
		if godot_joint == XRHandTracker.HAND_JOINT_INDEX_FINGER_METACARPAL or godot_joint == XRHandTracker.HAND_JOINT_MIDDLE_FINGER_METACARPAL or godot_joint == XRHandTracker.HAND_JOINT_RING_FINGER_METACARPAL:
			continue

		p_tracker.set_hand_joint_transform(godot_joint, p_wrist_pose * p_joint_transforms[carl_joint])
		p_tracker.set_hand_joint_flags(godot_joint, valid_flags)

		carl_joint += 1

	p_tracker.set_hand_joint_transform(XRHandTracker.HAND_JOINT_WRIST, p_wrist_pose)
	p_tracker.set_hand_joint_flags(XRHandTracker.HAND_JOINT_WRIST, valid_flags)

	# Estimate the palm joint. This won't be very accurate without the middle finger metacarpal, but it's only used
	# for playback, so hopefully, it doesn't really matter.
	var palm_t: Transform3D = p_wrist_pose
	# We start with the wrist pose, and move forward 2cm, to try and estimate the middle finger metacarpal.
	palm_t.origin = -p_wrist_pose.basis.z * 0.02
	# Then get the midpoint between the middle finger metacarpal and proximal.
	palm_t.origin = (palm_t.origin + p_tracker.get_hand_joint_transform(XRHandTracker.HAND_JOINT_MIDDLE_FINGER_PHALANX_PROXIMAL).origin) / 2.0

	p_tracker.set_hand_joint_transform(XRHandTracker.HAND_JOINT_PALM, palm_t)
	p_tracker.set_hand_joint_flags(XRHandTracker.HAND_JOINT_PALM, valid_flags)
	p_tracker.set_pose("default", palm_t, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	p_tracker.has_tracking_data = true
