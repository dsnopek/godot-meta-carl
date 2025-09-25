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

#include "carl_capture_helper.h"

Ref<CARLInputSample> CARLCaptureHelper::capture_input() {
	XRServer *xr_server = XRServer::get_singleton();
	ERR_FAIL_NULL_V(xr_server, Ref<CARLInputSample>());

	Ref<XRPositionalTracker> hmd_tracker = xr_server->get_tracker("head");
	Ref<XRHandTracker> left_hand = xr_server->get_tracker("/user/hand_tracker/left");
	Ref<XRHandTracker> right_hand = xr_server->get_tracker("/user/hand_tracker/right");

	return capture_input_from(hmd_tracker, left_hand, right_hand);
}

Ref<CARLInputSample> CARLCaptureHelper::capture_input_from(const Ref<XRPositionalTracker> &p_hmd_tracker, const Ref<XRHandTracker> &p_left_hand_tracker, const Ref<XRHandTracker> &p_right_hand_tracker) {
	Ref<CARLInputSample> input_sample;
	input_sample.instantiate();

	if (enabled_poses & CARLInputSample::POSE_HMD) {
		if (p_hmd_tracker.is_valid()) {
			input_sample->set_hmd_pose(p_hmd_tracker->get_pose("default")->get_transform());
		} else {
			return Ref<CARLInputSample>();
		}
	}

	if (enabled_poses & CARLInputSample::POSE_LEFT_WRIST || enabled_poses & CARLInputSample::POSE_LEFT_JOINTS) {
		if (p_left_hand_tracker.is_valid() && p_left_hand_tracker->get_has_tracking_data()) {
			input_sample->populate_from_hand_tracker(p_left_hand_tracker);

			prev_data[0].wrist_pose = input_sample->get_left_wrist_pose();
			prev_data[0].joint_poses = input_sample->get_left_hand_joint_poses().duplicate();
			prev_data[0].valid = true;
		} else {
			if (!prev_data[0].valid) {
				return Ref<CARLInputSample>();
			} else {
				input_sample->set_left_wrist_pose(prev_data[0].wrist_pose);
				input_sample->set_left_hand_joint_poses(prev_data[0].joint_poses.duplicate());
			}
		}
	}

	if (enabled_poses & CARLInputSample::POSE_RIGHT_WRIST || enabled_poses & CARLInputSample::POSE_RIGHT_JOINTS) {
		if (p_right_hand_tracker.is_valid() && p_right_hand_tracker->get_has_tracking_data()) {
			input_sample->populate_from_hand_tracker(p_right_hand_tracker);

			prev_data[1].wrist_pose = input_sample->get_right_wrist_pose();
			prev_data[1].joint_poses = input_sample->get_right_hand_joint_poses().duplicate();
			prev_data[1].valid = true;
		} else {
			if (!prev_data[1].valid) {
				return Ref<CARLInputSample>();
			} else {
				input_sample->set_right_wrist_pose(prev_data[1].wrist_pose);
				input_sample->set_right_hand_joint_poses(prev_data[1].joint_poses.duplicate());
			}
		}
	}

	input_sample->set_enabled_poses(enabled_poses);

	return input_sample;
}
