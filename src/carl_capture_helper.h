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

#include <godot_cpp/classes/xr_hand_tracker.hpp>

#include "carl_input_sample.h"

using namespace godot;

class CARLCaptureHelper {
	BitField<CARLInputSample::Pose> enabled_poses = 0;

	struct PreviousData {
		bool valid = false;
		Transform3D wrist_pose;
		TypedArray<Transform3D> joint_poses;
	};
	PreviousData prev_data[2];

public:
	Ref<CARLInputSample> capture_input();
	Ref<CARLInputSample> capture_input_from(const Ref<XRPositionalTracker> &p_hmd_tracker, const Ref<XRHandTracker> &p_left_hand_tracker, const Ref<XRHandTracker> &p_right_hand_tracker);

	CARLCaptureHelper(BitField<CARLInputSample::Pose> p_enabled_poses) {
		enabled_poses = p_enabled_poses;
	}
};
