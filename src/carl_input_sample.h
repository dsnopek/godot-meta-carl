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

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/classes/xr_hand_tracker.hpp>
#include <godot_cpp/core/type_info.hpp>

#include <carl/Carl.h>

using namespace godot;

class CARLInputSample : public RefCounted {
	GDCLASS(CARLInputSample, RefCounted);

public:
	enum Pose {
		POSE_HMD = 1,
		POSE_LEFT_WRIST = 2,
		POSE_RIGHT_WRIST = 4,
		POSE_LEFT_JOINTS = 8,
		POSE_RIGHT_JOINTS = 16,
	};

private:
	double timestamp = 0;
	Transform3D hmd_pose;
	TypedArray<Transform3D> left_hand_joint_poses;
	TypedArray<Transform3D> right_hand_joint_poses;
	BitField<Pose> enabled_poses = 0;

protected:
	static void _bind_methods();

public:
	void populate_from_hand_tracker(const Ref<XRHandTracker> &p_tracker);

	void set_timestamp(double p_timestamp);
	double get_timestamp() const;

	void set_hmd_pose(const Transform3D &p_pose);
	Transform3D get_hmd_pose() const;

	void set_left_hand_joint_poses(const TypedArray<Transform3D> &p_poses);
	TypedArray<Transform3D> get_left_hand_joint_poses() const;

	void set_right_hand_joint_poses(const TypedArray<Transform3D> &p_poses);
	TypedArray<Transform3D> get_right_hand_joint_poses() const;

	void set_enabled_poses(BitField<Pose> p_enabled_poses);
	BitField<Pose> get_enabled_posed() const;

	PackedByteArray serialize() const;
	static Ref<CARLInputSample> deserialize(const PackedByteArray &p_data);

	carl::InputSample get_carl_object() const;

	static void to_carl_transform(const Transform3D &p_godot_transform, carl::TransformT &r_carl_transform);
	static void from_carl_transform(const carl::TransformT &p_carl_transform, Transform3D &r_godot_transform);

	static void to_carl_hand_joint_poses(const TypedArray<Transform3D> &p_godot_transforms, std::array<carl::TransformT, static_cast<size_t>(carl::InputSample::Joint::COUNT)> &r_carl_transforms);
	static void from_carl_hand_joint_poses(const std::array<carl::TransformT, static_cast<size_t>(carl::InputSample::Joint::COUNT)> &p_carl_transforms, TypedArray<Transform3D> &r_godot_transforms);

	CARLInputSample();
	CARLInputSample(const carl::InputSample &p_carl_input_sample);
	~CARLInputSample();
};

VARIANT_BITFIELD_CAST(CARLInputSample::Pose);
