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

#pragma once

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/xr_hand_tracker.hpp>

#include <carl/Carl.h>

using namespace godot;

class CARLInputSample : public Resource {
	GDCLASS(CARLInputSample, Resource);

	Transform3D hmd_pose;
	Transform3D left_hand_joint_poses[XRHandTracker::HandJoint::HAND_JOINT_MAX];
	Transform3D right_hand_joint_poses[XRHandTracker::HandJoint::HAND_JOINT_MAX];

	carl::InputSample *carl_input_sample = nullptr;
	bool dirty = false;

protected:
	static void _bind_methods();

public:
	void populate_from_hand_tracker(const Ref<XRHandTracker> &p_tracker);

	void set_hmd_pose(const Transform3D &p_pose);
	Transform3D get_hmd_pose() const;

	void set_left_hand_joint_poses(const TypedArray<Transform3D> &p_poses);
	TypedArray<Transform3D> get_left_hand_joint_poses() const;

	void set_right_hand_joint_poses(const TypedArray<Transform3D> &p_poses);
	TypedArray<Transform3D> get_right_hand_joint_poses() const;

	PackedByteArray serialize() const;
	static Ref<CARLInputSample> deserialize(const PackedByteArray &p_data);

	carl::InputSample get_carl_object();

	CARLInputSample() = default;
	~CARLInputSample() override = default;
};
