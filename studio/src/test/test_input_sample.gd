extends Node2D


func _ready() -> void:
	test_serialization()


func test_serialization() -> void:
	var is1 := CARLInputSample.new()
	is1.enabled_poses = CARLInputSample.POSE_RIGHT_JOINTS

	var t := Transform3D()
	t = t.rotated(Vector3.ONE.normalized(), PI / 4.0)
	t.origin = Vector3(1.0, 2.0, 3.0)

	is1.right_hand_joint_poses[2] = t

	print("Before:")
	print(is1.right_hand_joint_poses[2])
	print("")

	var data: PackedByteArray = is1.serialize()
	print("Serialized:")
	print(data)
	print("")

	var is2 := CARLInputSample.deserialize(data)

	print("After:")
	print(is2.right_hand_joint_poses[2])
