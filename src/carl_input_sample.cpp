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
}

void CARLInputSample::populate_from_hand_tracker(const Ref<XRHandTracker> &p_tracker) {
}

void CARLInputSample::set_timestamp(double p_timestamp) {
	timestamp = p_timestamp;
	if (carl_input_sample) {
		carl_input_sample->Timestamp = p_timestamp;
	}
}

double CARLInputSample::get_timestamp() const {
	return timestamp;
}

void CARLInputSample::set_hmd_pose(const Transform3D &p_pose) {
	hmd_pose = p_pose;
	if (carl_input_sample) {
		carl_input_sample->HmdPose = to_carl_transform(p_pose);
	}
}

Transform3D CARLInputSample::get_hmd_pose() const {
	return hmd_pose;
}

void CARLInputSample::set_left_hand_joint_poses(const TypedArray<Transform3D> &p_poses) {
	ERR_FAIL_COND(p_poses.size() != XRHandTracker::HAND_JOINT_MAX);
	left_hand_joint_poses = p_poses;
	if (carl_input_sample) {
		// @todo Set the values on the CARL input sample.
	}
}

TypedArray<Transform3D> CARLInputSample::get_left_hand_joint_poses() const {
	return left_hand_joint_poses;
}

void CARLInputSample::set_right_hand_joint_poses(const TypedArray<Transform3D> &p_poses) {
	ERR_FAIL_COND(p_poses.size() != XRHandTracker::HAND_JOINT_MAX);
	right_hand_joint_poses = p_poses;
	if (carl_input_sample) {
		// @todo Set the values on the CARL input sample.
	}
}

TypedArray<Transform3D> CARLInputSample::get_right_hand_joint_poses() const {
	return right_hand_joint_poses;
}

PackedByteArray CARLInputSample::serialize() const {
	carl::InputSample *cis = get_carl_object();
	return PackedByteArray();
}

Ref<CARLInputSample> CARLInputSample::deserialize(const PackedByteArray &p_data) {
	return Ref<CARLInputSample>();
}

carl::InputSample *CARLInputSample::get_carl_object() const {
	if (carl_input_sample == nullptr) {
		carl_input_sample = new carl::InputSample();
	}

	// @todo Copy everything in

	return carl_input_sample;
}

carl::TransformT CARLInputSample::to_carl_transform(const Transform3D &p_godot_transform) {
	carl::TransformT carl_transform;
	const Vector3 *b = p_godot_transform.basis.rows;
	const Vector3 &o = p_godot_transform.origin;
	carl_transform.matrix().col(0) = Eigen::Vector<carl::NumberT, 4>(b[0][0], b[0][1], b[0][2], static_cast<carl::NumberT>(0));
	carl_transform.matrix().col(1) = Eigen::Vector<carl::NumberT, 4>(b[1][0], b[1][1], b[1][2], static_cast<carl::NumberT>(0));
	carl_transform.matrix().col(2) = Eigen::Vector<carl::NumberT, 4>(b[2][0], b[2][1], b[2][2], static_cast<carl::NumberT>(0));
	carl_transform.matrix().col(3) = Eigen::Vector<carl::NumberT, 4>(o[0], o[1], o[2], static_cast<carl::NumberT>(0));
	return carl_transform;
}

Transform3D CARLInputSample::from_carl_transform(const carl::TransformT &p_carl_transform) {
	auto &m = p_carl_transform.matrix();
	Basis b(
		m(0, 0), m(0, 1), m(0, 2),
		m(1, 0), m(1, 1), m(1, 2),
		m(2, 0), m(2, 1), m(2, 2));
	Vector3 o(m(3, 0), m(3, 1), m(3, 2));
	return Transform3D(b, o);
}

CARLInputSample::CARLInputSample() {
	left_hand_joint_poses.resize(XRHandTracker::HAND_JOINT_MAX);
	right_hand_joint_poses.resize(XRHandTracker::HAND_JOINT_MAX);
}

CARLInputSample::~CARLInputSample() {
	if (carl_input_sample) {
		delete carl_input_sample;
	}
}
