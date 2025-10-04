extends Node3D

const JointScene = preload("res://src/main/joint.tscn")

var joints := []

func _ready() -> void:
	for i in range(XRHandTracker.HAND_JOINT_MAX):
		var joint = JointScene.instantiate()
		add_child(joint)
		joints.push_back(joint)


func update_joints(p_joint_transforms: Array[Transform3D]) -> void:
	for i in range(XRHandTracker.HAND_JOINT_MAX):
		joints[i].transform = p_joint_transforms[i]
