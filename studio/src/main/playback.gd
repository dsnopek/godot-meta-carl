extends Node3D

const JointDebugger = preload("res://src/main/joint_debugger.gd")

const LEFT_HAND_MESH_ROTATION := Quaternion(0.5, 0.5, 0.5, 0.5)
const RIGHT_HAND_MESH_ROTATION := Quaternion(0.5, -0.5, 0.5, -0.5)

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
	right_hand.visible = (enabled_poses & CARLInputSample.POSE_RIGHT_WRIST) or (enabled_poses & CARLInputSample.POSE_RIGHT_JOINTS)

	var left_wrist_pose: Transform3D = p_input_sample.left_wrist_pose if (enabled_poses & CARLInputSample.POSE_LEFT_WRIST) else left_hand_default_transform
	var right_wrist_pose: Transform3D = p_input_sample.right_wrist_pose if (enabled_poses & CARLInputSample.POSE_RIGHT_WRIST) else right_hand_default_transform

	if DEBUG_JOINTS:
		left_hand.transform = left_wrist_pose
		right_hand.transform = right_wrist_pose
		if enabled_poses & CARLInputSample.POSE_LEFT_JOINTS:
			left_hand_joint_debugger.update_joints(p_input_sample.left_hand_joint_poses)
		if enabled_poses & CARLInputSample.POSE_RIGHT_JOINTS:
			right_hand_joint_debugger.update_joints(p_input_sample.right_hand_joint_poses)
	else:
		if enabled_poses & CARLInputSample.POSE_LEFT_JOINTS:
			p_input_sample.apply_to_hand_tracker(left_hand_tracker)
			left_hand_mesh.transform = Transform3D()
		elif enabled_poses & CARLInputSample.POSE_LEFT_WRIST:
			_apply_wrist_trajectory(left_hand_mesh, left_hand_tracker, LEFT_HAND_MESH_ROTATION, left_wrist_pose)

		if enabled_poses & CARLInputSample.POSE_RIGHT_JOINTS:
			p_input_sample.apply_to_hand_tracker(right_hand_tracker)
			right_hand_mesh.transform = Transform3D()
		elif enabled_poses & CARLInputSample.POSE_RIGHT_WRIST:
			_apply_wrist_trajectory(right_hand_mesh, right_hand_tracker, RIGHT_HAND_MESH_ROTATION, right_wrist_pose)

func _apply_wrist_trajectory(p_hand_mesh: OpenXRFbHandTrackingMesh, p_tracker: XRHandTracker, p_mesh_rotation: Quaternion, p_wrist_pose: Transform3D) -> void:
	p_hand_mesh.reset_bone_poses()
	p_hand_mesh.transform = Transform3D(Basis(p_mesh_rotation), Vector3.ZERO)
	for joint in range(XRHandTracker.HAND_JOINT_MAX):
		p_tracker.set_hand_joint_transform(joint, Transform3D())
		p_tracker.set_hand_joint_flags(joint, 0)
	p_tracker.set_pose("default", p_wrist_pose, Vector3(), Vector3(), XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	p_tracker.has_tracking_data = true
