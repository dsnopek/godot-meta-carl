/*************************************************************************/
/* Copyright (c) 2025 David Snopek                                       */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "carl_input_sample.h"

void CARLInputSample::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_timestamp", "timestamp"), &CARLInputSample::set_timestamp);
	ClassDB::bind_method(D_METHOD("get_timestamp"), &CARLInputSample::get_timestamp);

	ClassDB::bind_method(D_METHOD("set_hmd_pose", "hmd_pose"), &CARLInputSample::set_hmd_pose);
	ClassDB::bind_method(D_METHOD("get_hmd_pose"), &CARLInputSample::get_hmd_pose);

	ClassDB::bind_method(D_METHOD("set_left_hand_joint_poses", "poses"), &CARLInputSample::set_left_hand_joint_poses);
	ClassDB::bind_method(D_METHOD("get_left_hand_joint_poses"), &CARLInputSample::get_left_hand_joint_poses);

	ClassDB::bind_method(D_METHOD("set_right_hand_joint_poses", "poses"), &CARLInputSample::set_right_hand_joint_poses);
	ClassDB::bind_method(D_METHOD("get_right_hand_joint_poses"), &CARLInputSample::get_right_hand_joint_poses);

	ClassDB::bind_method(D_METHOD("set_enabled_poses", "enabled_poses"), &CARLInputSample::set_enabled_poses);
	ClassDB::bind_method(D_METHOD("get_enabled_poses"), &CARLInputSample::get_enabled_posed);

	ClassDB::bind_method(D_METHOD("serialize"), &CARLInputSample::serialize);
	ClassDB::bind_static_method("CARLInputSample", D_METHOD("deserialize", "data"), &CARLInputSample::deserialize);

	ClassDB::bind_method(D_METHOD("populate_from_hand_tracker", "hand_tracker"), &CARLInputSample::populate_from_hand_tracker);

	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "timestamp"), "set_timestamp", "get_timestamp");
	ADD_PROPERTY(PropertyInfo(Variant::TRANSFORM3D, "hmd_pose"), "set_hmd_pose", "get_hmd_pose");
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "left_hand_joint_poses", PROPERTY_HINT_ARRAY_TYPE, vformat("%s", Variant::TRANSFORM3D)), "set_left_hand_joint_poses", "get_left_hand_joint_poses");
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "right_hand_joint_poses", PROPERTY_HINT_ARRAY_TYPE, vformat("%s", Variant::TRANSFORM3D)), "set_right_hand_joint_poses", "get_right_hand_joint_poses");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "enabled_poses", PROPERTY_HINT_FLAGS, "HMD,Left Wrist,Right Wrist,Left Joints,Right Joints"), "set_enabled_poses", "get_enabled_poses");

	BIND_BITFIELD_FLAG(Pose::POSE_HMD);
	BIND_BITFIELD_FLAG(Pose::POSE_LEFT_WRIST);
	BIND_BITFIELD_FLAG(Pose::POSE_RIGHT_WRIST);
	BIND_BITFIELD_FLAG(Pose::POSE_LEFT_JOINTS);
	BIND_BITFIELD_FLAG(Pose::POSE_RIGHT_JOINTS);
}

void CARLInputSample::populate_from_hand_tracker(const Ref<XRHandTracker> &p_tracker) {
	XRPositionalTracker::TrackerHand hand = p_tracker->get_tracker_hand();
	ERR_FAIL_COND(hand != XRPositionalTracker::TRACKER_HAND_LEFT && hand != XRPositionalTracker::TRACKER_HAND_RIGHT);

	TypedArray<Transform3D> *poses = (hand == XRPositionalTracker::TRACKER_HAND_LEFT) ? &left_hand_joint_poses : &right_hand_joint_poses;

	for (int i = 0; i < XRHandTracker::HAND_JOINT_MAX; i++) {
		(*poses)[i] = p_tracker->get_hand_joint_transform((XRHandTracker::HandJoint)i);
	}
}

void CARLInputSample::set_timestamp(double p_timestamp) {
	timestamp = p_timestamp;
}

double CARLInputSample::get_timestamp() const {
	return timestamp;
}

void CARLInputSample::set_hmd_pose(const Transform3D &p_pose) {
	hmd_pose = p_pose;
}

Transform3D CARLInputSample::get_hmd_pose() const {
	return hmd_pose;
}

void CARLInputSample::set_left_hand_joint_poses(const TypedArray<Transform3D> &p_poses) {
	ERR_FAIL_COND(p_poses.size() != XRHandTracker::HAND_JOINT_MAX);
	left_hand_joint_poses = p_poses;
}

TypedArray<Transform3D> CARLInputSample::get_left_hand_joint_poses() const {
	return left_hand_joint_poses;
}

void CARLInputSample::set_right_hand_joint_poses(const TypedArray<Transform3D> &p_poses) {
	ERR_FAIL_COND(p_poses.size() != XRHandTracker::HAND_JOINT_MAX);
	right_hand_joint_poses = p_poses;
}

TypedArray<Transform3D> CARLInputSample::get_right_hand_joint_poses() const {
	return right_hand_joint_poses;
}

void CARLInputSample::set_enabled_poses(BitField<Pose> p_enabled_poses) {
	enabled_poses = p_enabled_poses;
	update_carl_object();
}

BitField<CARLInputSample::Pose> CARLInputSample::get_enabled_posed() const {
	return enabled_poses;
}

PackedByteArray CARLInputSample::serialize() const {
	carl::InputSample cis = get_carl_object();
	std::vector<uint8_t> bytes;
	carl::Serialization serialization{ bytes };
	cis.serialize(serialization);

	PackedByteArray ret;
	ret.resize(bytes.size());
	memcpy(ret.ptrw(), bytes.data(), bytes.size());

	return ret;
}

Ref<CARLInputSample> CARLInputSample::deserialize(const PackedByteArray &p_data) {
	carl::Deserialization deserialization{ p_data.ptr() };
	carl::InputSample cis(deserialization);

	return Ref<CARLInputSample>(memnew(CARLInputSample(cis)));
}

carl::InputSample CARLInputSample::get_carl_object() const {
	carl::InputSample cis;

	if (enabled_poses.has_flag(POSE_HMD)) {
		cis.HmdPose.emplace();
		to_carl_transform(hmd_pose, *cis.HmdPose);
	} else {
		cis.HmdPose.reset();
	}

	if (enabled_poses.has_flag(POSE_LEFT_WRIST)) {
		cis.LeftWristPose.emplace();
		to_carl_transform(left_hand_joint_poses[XRHandTracker::HAND_JOINT_WRIST], *cis.LeftWristPose);
	} else {
		cis.LeftWristPose.reset();
	}

	if (enabled_poses.has_flag(POSE_RIGHT_WRIST)) {
		cis.RightWristPose.emplace();
		to_carl_transform(right_hand_joint_poses[XRHandTracker::HAND_JOINT_WRIST], *cis.RightWristPose);
	} else {
		cis.RightWristPose.reset();
	}

	if (enabled_poses.has_flag(POSE_LEFT_JOINTS)) {
		to_carl_hand_joint_poses(left_hand_joint_poses, cis.LeftHandJointPoses);
	} else {
		cis.LeftHandJointPoses.reset();
	}

	if (enabled_poses.has_flag(POSE_RIGHT_JOINTS)) {
		to_carl_hand_joint_poses(right_hand_joint_poses, cis.RightHandJointPoses);
	} else {
		cis.RightHandJointPoses.reset();
	}

	return cis;
}

void CARLInputSample::to_carl_transform(const Transform3D &p_godot_transform, carl::TransformT &r_carl_transform) {
	const Vector3 *b = p_godot_transform.basis.rows;
	const Vector3 &o = p_godot_transform.origin;
	r_carl_transform.matrix().col(0) = Eigen::Vector<carl::NumberT, 4>(b[0][0], b[0][1], b[0][2], static_cast<carl::NumberT>(0));
	r_carl_transform.matrix().col(1) = Eigen::Vector<carl::NumberT, 4>(b[1][0], b[1][1], b[1][2], static_cast<carl::NumberT>(0));
	r_carl_transform.matrix().col(2) = Eigen::Vector<carl::NumberT, 4>(b[2][0], b[2][1], b[2][2], static_cast<carl::NumberT>(0));
	r_carl_transform.matrix().col(3) = Eigen::Vector<carl::NumberT, 4>(o[0], o[1], o[2], static_cast<carl::NumberT>(0));
}

void CARLInputSample::from_carl_transform(const carl::TransformT &p_carl_transform, Transform3D &r_godot_transform) {
	auto &m = p_carl_transform.matrix();
	Vector3 *b = r_godot_transform.basis.rows;
	for (int i = 0; i < 3; i++) {
		for (int j = 0; j < 3; j++) {
			b[i][j] = m(i, j);
		}
	}
	r_godot_transform.origin = Vector3(m(3, 0), m(3, 1), m(3, 2));
}

void CARLInputSample::to_carl_hand_joint_poses(const TypedArray<Transform3D> &p_godot_transforms, std::optional<std::array<carl::TransformT, static_cast<size_t>(carl::InputSample::Joint::COUNT)>> &r_carl_transforms) {
	ERR_FAIL_COND(p_godot_transforms.size() != XRHandTracker::HAND_JOINT_MAX);

	if (!r_carl_transforms.has_value()) {
		r_carl_transforms.emplace();
	}

	// The CARL joint set appears to be at least partially based on the OVR joint set, rather than the OpenXR one.
	// It only has slots for the metacarpal joints of the thumb and pinky, but it appears not to use them anyway.
	// The base of each finger appears to be the proximal joint.
	// We fill them all, even though they are mostly unused - perhaps they will be used in the future?

	int godot_joint = XRHandTracker::HAND_JOINT_THUMB_METACARPAL;
	for (uint64_t i = i; i < (uint64_t)carl::InputSample::Joint::COUNT; i++) {
		// Skip the missing metacarpal joints.
		if (godot_joint == XRHandTracker::HAND_JOINT_INDEX_FINGER_METACARPAL ||
			godot_joint == XRHandTracker::HAND_JOINT_MIDDLE_FINGER_METACARPAL ||
			godot_joint == XRHandTracker::HAND_JOINT_RING_FINGER_METACARPAL) {
			godot_joint++;
		}

		to_carl_transform(p_godot_transforms[godot_joint], r_carl_transforms->at(i));

		godot_joint++;
	}
}

void CARLInputSample::from_carl_hand_joint_poses(const std::optional<std::array<carl::TransformT, static_cast<size_t>(carl::InputSample::Joint::COUNT)>> p_carl_transforms, TypedArray<Transform3D> &r_godot_transforms) {
	ERR_FAIL_COND(!p_carl_transforms.has_value());
	ERR_FAIL_COND(r_godot_transforms.size() != XRHandTracker::HAND_JOINT_MAX);

	// See `to_carl_hand_joint_poses()` for an explanation of how (I think) the CARL joint set is laid out.

	int godot_joint = XRHandTracker::HAND_JOINT_THUMB_METACARPAL;
	for (uint64_t i = 1; i < (uint64_t)carl::InputSample::Joint::COUNT; i++) {
		// Skip the missing metacarpal joints.
		if (godot_joint == XRHandTracker::HAND_JOINT_INDEX_FINGER_METACARPAL ||
			godot_joint == XRHandTracker::HAND_JOINT_MIDDLE_FINGER_METACARPAL ||
			godot_joint == XRHandTracker::HAND_JOINT_RING_FINGER_METACARPAL) {
			godot_joint++;
		}

		// We need to use this temporary, because a TypedArray<Transform3D> actually holds Variant - not Transform3D.
		Transform3D t;
		from_carl_transform(p_carl_transforms->at(i), t);
		r_godot_transforms[godot_joint] = t;

		godot_joint++;
	}
}

CARLInputSample::CARLInputSample() {
	left_hand_joint_poses.resize(XRHandTracker::HAND_JOINT_MAX);
	right_hand_joint_poses.resize(XRHandTracker::HAND_JOINT_MAX);
}

CARLInputSample::CARLInputSample(const carl::InputSample &p_cis) : CARLInputSample() {
	if (p_cis.HmdPose.has_value()) {
		enabled_poses.set_flag(POSE_HMD);
		from_carl_transform(*p_cis.HmdPose, hmd_pose);
	}

	if (p_cis.LeftHandJointPoses.has_value()) {
		from_carl_hand_joint_poses(p_cis.LeftHandJointPoses, left_hand_joint_poses);
	}

	if (p_cis.RightHandJointPoses.has_value()) {
		from_carl_hand_joint_poses(p_cis.RightHandJointPoses, right_hand_joint_poses);
	}

	if (p_cis.LeftWristPose.has_value()) {
		Transform3D left_wrist_pose;
		from_carl_transform(*p_cis.LeftWristPose, left_wrist_pose);
		left_hand_joint_poses[XRHandTracker::HAND_JOINT_WRIST] = left_wrist_pose;
	}

	if (p_cis.RightWristPose.has_value()) {
		Transform3D right_wrist_pose;
		from_carl_transform(*p_cis.RightWristPose, right_wrist_pose);
		right_hand_joint_poses[XRHandTracker::HAND_JOINT_WRIST] = right_wrist_pose;
	}
}

CARLInputSample::~CARLInputSample() {
}
