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

	ClassDB::bind_method(D_METHOD("set_hmd_pose", "pose"), &CARLInputSample::set_hmd_pose);
	ClassDB::bind_method(D_METHOD("get_hmd_pose"), &CARLInputSample::get_hmd_pose);

	ClassDB::bind_method(D_METHOD("set_left_wrist_pose", "pose"), &CARLInputSample::set_left_wrist_pose);
	ClassDB::bind_method(D_METHOD("get_left_wrist_pose"), &CARLInputSample::get_left_wrist_pose);

	ClassDB::bind_method(D_METHOD("set_right_wrist_pose", "pose"), &CARLInputSample::set_right_wrist_pose);
	ClassDB::bind_method(D_METHOD("get_right_wrist_pose"), &CARLInputSample::get_right_wrist_pose);

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
	ADD_PROPERTY(PropertyInfo(Variant::TRANSFORM3D, "left_wrist_pose"), "set_left_wrist_pose", "get_left_wrist_pose");
	ADD_PROPERTY(PropertyInfo(Variant::TRANSFORM3D, "right_wrist_pose"), "set_right_wrist_pose", "get_right_wrist_pose");
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "left_hand_joint_poses", PROPERTY_HINT_ARRAY_TYPE, vformat("%s", Variant::TRANSFORM3D)), "set_left_hand_joint_poses", "get_left_hand_joint_poses");
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "right_hand_joint_poses", PROPERTY_HINT_ARRAY_TYPE, vformat("%s", Variant::TRANSFORM3D)), "set_right_hand_joint_poses", "get_right_hand_joint_poses");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "enabled_poses", PROPERTY_HINT_FLAGS, "HMD,Left Wrist,Right Wrist,Left Joints,Right Joints"), "set_enabled_poses", "get_enabled_poses");

	BIND_ENUM_CONSTANT(HAND_JOINT_THUMB0);
	BIND_ENUM_CONSTANT(HAND_JOINT_THUMB1);
	BIND_ENUM_CONSTANT(HAND_JOINT_THUMB2);
	BIND_ENUM_CONSTANT(HAND_JOINT_THUMB3);
	BIND_ENUM_CONSTANT(HAND_JOINT_THUMB4);
	BIND_ENUM_CONSTANT(HAND_JOINT_INDEX1);
	BIND_ENUM_CONSTANT(HAND_JOINT_INDEX2);
	BIND_ENUM_CONSTANT(HAND_JOINT_INDEX3);
	BIND_ENUM_CONSTANT(HAND_JOINT_INDEX4);
	BIND_ENUM_CONSTANT(HAND_JOINT_MIDDLE1);
	BIND_ENUM_CONSTANT(HAND_JOINT_MIDDLE2);
	BIND_ENUM_CONSTANT(HAND_JOINT_MIDDLE3);
	BIND_ENUM_CONSTANT(HAND_JOINT_MIDDLE4);
	BIND_ENUM_CONSTANT(HAND_JOINT_RING1);
	BIND_ENUM_CONSTANT(HAND_JOINT_RING2);
	BIND_ENUM_CONSTANT(HAND_JOINT_RING3);
	BIND_ENUM_CONSTANT(HAND_JOINT_RING4);
	BIND_ENUM_CONSTANT(HAND_JOINT_PINKY0);
	BIND_ENUM_CONSTANT(HAND_JOINT_PINKY1);
	BIND_ENUM_CONSTANT(HAND_JOINT_PINKY2);
	BIND_ENUM_CONSTANT(HAND_JOINT_PINKY3);
	BIND_ENUM_CONSTANT(HAND_JOINT_PINKY4);
	BIND_ENUM_CONSTANT(HAND_JOINT_MAX);

	BIND_BITFIELD_FLAG(POSE_HMD);
	BIND_BITFIELD_FLAG(POSE_LEFT_WRIST);
	BIND_BITFIELD_FLAG(POSE_RIGHT_WRIST);
	BIND_BITFIELD_FLAG(POSE_LEFT_JOINTS);
	BIND_BITFIELD_FLAG(POSE_RIGHT_JOINTS);
}

void CARLInputSample::populate_from_hand_tracker(const Ref<XRHandTracker> &p_tracker) {
	ERR_FAIL_COND(p_tracker.is_null());

	XRPositionalTracker::TrackerHand hand = p_tracker->get_tracker_hand();
	ERR_FAIL_COND(hand != XRPositionalTracker::TRACKER_HAND_LEFT && hand != XRPositionalTracker::TRACKER_HAND_RIGHT);

	TypedArray<Transform3D> &jts = (hand == XRPositionalTracker::TRACKER_HAND_LEFT) ? left_hand_joint_poses : right_hand_joint_poses;

	Transform3D ht = p_tracker->get_hand_joint_transform(XRHandTracker::HAND_JOINT_WRIST);
	Transform3D hti = ht.affine_inverse();

	// The CARL joint set appears to be at least partially based on the OVR joint set, rather than the OpenXR one.
	// It only has slots for the metacarpal joints of the thumb and pinky, but it appears not to use them anyway.
	// The base of each finger appears to be the proximal joint.
	// We fill them all, even though they are mostly unused - perhaps they will be used in the future?

	int carl_joint = 1;
	for (int godot_joint = XRHandTracker::HAND_JOINT_THUMB_METACARPAL; godot_joint < XRHandTracker::HAND_JOINT_MAX; godot_joint++) {
		// Skip the missing metacarpal joints.
		if (godot_joint == XRHandTracker::HAND_JOINT_INDEX_FINGER_METACARPAL ||
				godot_joint == XRHandTracker::HAND_JOINT_MIDDLE_FINGER_METACARPAL ||
				godot_joint == XRHandTracker::HAND_JOINT_RING_FINGER_METACARPAL) {
			continue;
		}

		// We make the joints relative to the wrist.
		jts[carl_joint] = hti * p_tracker->get_hand_joint_transform(static_cast<XRHandTracker::HandJoint>(godot_joint));

		carl_joint++;
	}

	// Duplicate the thumb metacarpal joint.
	jts[0] = jts[1];

	if (hand == XRPositionalTracker::TRACKER_HAND_LEFT) {
		left_wrist_pose = ht;
	} else {
		right_wrist_pose = ht;
	}
}

void CARLInputSample::apply_to_hand_tracker(const Ref<XRHandTracker> &p_tracker) {
	ERR_FAIL_COND(p_tracker.is_null());

	XRPositionalTracker::TrackerHand hand = p_tracker->get_tracker_hand();
	ERR_FAIL_COND(hand != XRPositionalTracker::TRACKER_HAND_LEFT && hand != XRPositionalTracker::TRACKER_HAND_RIGHT);

	constexpr uint64_t valid_flags = XRHandTracker::HAND_JOINT_FLAG_POSITION_TRACKED | XRHandTracker::HAND_JOINT_FLAG_POSITION_VALID | XRHandTracker::HAND_JOINT_FLAG_ORIENTATION_TRACKED | XRHandTracker::HAND_JOINT_FLAG_ORIENTATION_VALID;

	TypedArray<Transform3D> &jts = (hand == XRPositionalTracker::TRACKER_HAND_LEFT) ? left_hand_joint_poses : right_hand_joint_poses;
	Transform3D ht = (hand == XRPositionalTracker::TRACKER_HAND_LEFT) ? left_wrist_pose : right_wrist_pose;

	int carl_joint = 1;
	for (int godot_joint = XRHandTracker::HAND_JOINT_THUMB_METACARPAL; godot_joint < XRHandTracker::HAND_JOINT_MAX; godot_joint++) {
		// Skip the missing metacarpal joints.
		if (godot_joint == XRHandTracker::HAND_JOINT_INDEX_FINGER_METACARPAL ||
				godot_joint == XRHandTracker::HAND_JOINT_MIDDLE_FINGER_METACARPAL ||
				godot_joint == XRHandTracker::HAND_JOINT_RING_FINGER_METACARPAL) {
			continue;
		}

		// We make the joints relative to the wrist.
		p_tracker->set_hand_joint_transform((XRHandTracker::HandJoint)godot_joint, ht * (Transform3D)jts[carl_joint]);
		p_tracker->set_hand_joint_flags((XRHandTracker::HandJoint)godot_joint, valid_flags);

		carl_joint++;
	}

	p_tracker->set_hand_joint_transform(XRHandTracker::HAND_JOINT_WRIST, ht);
	p_tracker->set_hand_joint_flags(XRHandTracker::HAND_JOINT_WRIST, valid_flags);

	// Estimate the missing joints!

	// Middle finger metacarpal = take the wrist pose and move forward 2cm.
	Transform3D middle_finger_metacarpal_t = ht;
	middle_finger_metacarpal_t.origin = middle_finger_metacarpal_t.basis.get_column(2) * -0.02;
	p_tracker->set_hand_joint_transform(XRHandTracker::HAND_JOINT_MIDDLE_FINGER_METACARPAL, middle_finger_metacarpal_t);
	p_tracker->set_hand_joint_flags(XRHandTracker::HAND_JOINT_MIDDLE_FINGER_METACARPAL, valid_flags);

	// Ring finger metacarpal = take the middle finger metacarpal and move 1cm to the left.
	Transform3D ring_finger_metacarpal_t = middle_finger_metacarpal_t;
	ring_finger_metacarpal_t.origin = ring_finger_metacarpal_t.basis.get_column(0) * -0.01;
	p_tracker->set_hand_joint_transform(XRHandTracker::HAND_JOINT_RING_FINGER_METACARPAL, ring_finger_metacarpal_t);
	p_tracker->set_hand_joint_flags(XRHandTracker::HAND_JOINT_RING_FINGER_METACARPAL, valid_flags);


	// Index finger metacarpal = take the middle finger metacarpal and move 1cm to the right.
	Transform3D index_finger_metacarpal_t = middle_finger_metacarpal_t;
	index_finger_metacarpal_t.origin = middle_finger_metacarpal_t.basis.get_column(0) * 0.01;
	Vector3 index_finger_metacarpal_v = (p_tracker->get_hand_joint_transform(XRHandTracker::HAND_JOINT_INDEX_FINGER_PHALANX_PROXIMAL).origin - index_finger_metacarpal_t.origin).normalized();
	index_finger_metacarpal_t.basis = Basis::looking_at(index_finger_metacarpal_v, middle_finger_metacarpal_t.basis.get_column(1));
	p_tracker->set_hand_joint_transform(XRHandTracker::HAND_JOINT_INDEX_FINGER_METACARPAL, index_finger_metacarpal_t);
	p_tracker->set_hand_joint_flags(XRHandTracker::HAND_JOINT_INDEX_FINGER_METACARPAL, valid_flags);

	// Palm = the midpoint between the middle finger metacarpal and proximal joint.
	Transform3D palm_t = middle_finger_metacarpal_t;
	palm_t.origin = (palm_t.origin + p_tracker->get_hand_joint_transform(XRHandTracker::HAND_JOINT_MIDDLE_FINGER_PHALANX_PROXIMAL).origin) / 2.0;
	p_tracker->set_hand_joint_transform(XRHandTracker::HAND_JOINT_PALM, palm_t);
	p_tracker->set_hand_joint_flags(XRHandTracker::HAND_JOINT_PALM, valid_flags);

	p_tracker->set_pose("default", palm_t, Vector3(), Vector3(), XRPose::XR_TRACKING_CONFIDENCE_HIGH);
	p_tracker->set_has_tracking_data(true);
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

void CARLInputSample::set_left_wrist_pose(const Transform3D &p_pose) {
	left_wrist_pose = p_pose;
}

Transform3D CARLInputSample::get_left_wrist_pose() const {
	return left_wrist_pose;
}

void CARLInputSample::set_right_wrist_pose(const Transform3D &p_pose) {
	right_wrist_pose = p_pose;
}

Transform3D CARLInputSample::get_right_wrist_pose() const {
	return right_wrist_pose;
}

void CARLInputSample::set_left_hand_joint_poses(const TypedArray<Transform3D> &p_poses) {
	ERR_FAIL_COND(p_poses.size() != static_cast<int64_t>(carl::InputSample::Joint::COUNT));
	left_hand_joint_poses = p_poses;
}

TypedArray<Transform3D> CARLInputSample::get_left_hand_joint_poses() const {
	return left_hand_joint_poses;
}

void CARLInputSample::set_right_hand_joint_poses(const TypedArray<Transform3D> &p_poses) {
	ERR_FAIL_COND(p_poses.size() != static_cast<int64_t>(carl::InputSample::Joint::COUNT));
	right_hand_joint_poses = p_poses;
}

TypedArray<Transform3D> CARLInputSample::get_right_hand_joint_poses() const {
	return right_hand_joint_poses;
}

void CARLInputSample::set_enabled_poses(BitField<Pose> p_enabled_poses) {
	enabled_poses = p_enabled_poses;
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

	cis.Timestamp = timestamp;

	if (enabled_poses.has_flag(POSE_HMD)) {
		cis.HmdPose.emplace();
		to_carl_transform(hmd_pose, *cis.HmdPose);
	}

	if (enabled_poses.has_flag(POSE_LEFT_WRIST)) {
		cis.LeftWristPose.emplace();
		to_carl_transform(left_wrist_pose, *cis.LeftWristPose);
	}

	if (enabled_poses.has_flag(POSE_RIGHT_WRIST)) {
		cis.RightWristPose.emplace();
		to_carl_transform(right_wrist_pose, *cis.RightWristPose);
	}

	if (enabled_poses.has_flag(POSE_LEFT_JOINTS)) {
		cis.LeftHandJointPoses.emplace();
		to_carl_hand_joint_poses(left_hand_joint_poses, *cis.LeftHandJointPoses);
	}

	if (enabled_poses.has_flag(POSE_RIGHT_JOINTS)) {
		cis.RightHandJointPoses.emplace();
		to_carl_hand_joint_poses(right_hand_joint_poses, *cis.RightHandJointPoses);
	}

	return cis;
}

void CARLInputSample::to_carl_transform(const Transform3D &p_godot_transform, carl::TransformT &r_carl_transform) {
	const Vector3 c0 = p_godot_transform.basis.get_column(0);
	const Vector3 c1 = p_godot_transform.basis.get_column(1);
	const Vector3 c2 = p_godot_transform.basis.get_column(2);

	r_carl_transform.linear().col(0) << static_cast<carl::NumberT>(c0.x),
			static_cast<carl::NumberT>(c0.y),
			static_cast<carl::NumberT>(c0.z);

	r_carl_transform.linear().col(1) << static_cast<carl::NumberT>(c1.x),
			static_cast<carl::NumberT>(c1.y),
			static_cast<carl::NumberT>(c1.z);

	r_carl_transform.linear().col(2) << static_cast<carl::NumberT>(c2.x),
			static_cast<carl::NumberT>(c2.y),
			static_cast<carl::NumberT>(c2.z);

	r_carl_transform.translation() << static_cast<carl::NumberT>(p_godot_transform.origin.x),
			static_cast<carl::NumberT>(p_godot_transform.origin.y),
			static_cast<carl::NumberT>(p_godot_transform.origin.z);
}

void CARLInputSample::from_carl_transform(const carl::TransformT &p_carl_transform, Transform3D &r_godot_transform) {
	const auto &m = p_carl_transform.linear();
	const auto &o = p_carl_transform.translation();

	r_godot_transform.basis.set_column(0, Vector3(static_cast<real_t>(m(0, 0)), static_cast<real_t>(m(1, 0)), static_cast<real_t>(m(2, 0))));
	r_godot_transform.basis.set_column(1, Vector3(static_cast<real_t>(m(0, 1)), static_cast<real_t>(m(1, 1)), static_cast<real_t>(m(2, 1))));
	r_godot_transform.basis.set_column(2, Vector3(static_cast<real_t>(m(0, 2)), static_cast<real_t>(m(1, 2)), static_cast<real_t>(m(2, 2))));

	r_godot_transform.origin = Vector3(
			static_cast<real_t>(o(0)),
			static_cast<real_t>(o(1)),
			static_cast<real_t>(o(2)));
}

void CARLInputSample::to_carl_hand_joint_poses(const TypedArray<Transform3D> &p_godot_transforms, std::array<carl::TransformT, static_cast<size_t>(carl::InputSample::Joint::COUNT)> &r_carl_transforms) {
	ERR_FAIL_COND(p_godot_transforms.size() != static_cast<int64_t>(carl::InputSample::Joint::COUNT));

	for (uint64_t i = 0; i < static_cast<uint64_t>(carl::InputSample::Joint::COUNT); i++) {
		to_carl_transform(p_godot_transforms[i], r_carl_transforms.at(i));
	}
}

void CARLInputSample::from_carl_hand_joint_poses(const std::array<carl::TransformT, static_cast<size_t>(carl::InputSample::Joint::COUNT)> &p_carl_transforms, TypedArray<Transform3D> &r_godot_transforms) {
	ERR_FAIL_COND(r_godot_transforms.size() != static_cast<int64_t>(carl::InputSample::Joint::COUNT));

	for (uint64_t i = 0; i < static_cast<uint64_t>(carl::InputSample::Joint::COUNT); i++) {
		// We need to use this temporary, because a TypedArray<Transform3D> actually holds Variant - not Transform3D.
		Transform3D t;
		from_carl_transform(p_carl_transforms.at(i), t);
		r_godot_transforms[i] = t;
	}
}

CARLInputSample::CARLInputSample() {
	left_hand_joint_poses.resize(static_cast<int64_t>(carl::InputSample::Joint::COUNT));
	right_hand_joint_poses.resize(static_cast<int64_t>(carl::InputSample::Joint::COUNT));
}

CARLInputSample::CARLInputSample(const carl::InputSample &p_cis) :
		CARLInputSample() {
	timestamp = p_cis.Timestamp;

	if (p_cis.HmdPose.has_value()) {
		enabled_poses.set_flag(POSE_HMD);
		from_carl_transform(*p_cis.HmdPose, hmd_pose);
	}

	if (p_cis.LeftHandJointPoses.has_value()) {
		enabled_poses.set_flag(POSE_LEFT_JOINTS);
		from_carl_hand_joint_poses(*p_cis.LeftHandJointPoses, left_hand_joint_poses);
	}

	if (p_cis.RightHandJointPoses.has_value()) {
		enabled_poses.set_flag(POSE_RIGHT_JOINTS);
		from_carl_hand_joint_poses(*p_cis.RightHandJointPoses, right_hand_joint_poses);
	}

	if (p_cis.LeftWristPose.has_value()) {
		enabled_poses.set_flag(POSE_LEFT_WRIST);
		from_carl_transform(*p_cis.LeftWristPose, left_wrist_pose);
	}

	if (p_cis.RightWristPose.has_value()) {
		enabled_poses.set_flag(POSE_RIGHT_WRIST);
		from_carl_transform(*p_cis.RightWristPose, right_wrist_pose);
	}
}

CARLInputSample::~CARLInputSample() {
}
