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

#include "carl_session.h"

#include <godot_cpp/classes/time.hpp>

#include "carl_definition.h"
#include "carl_input_sample.h"
#include "carl_recognizer.h"

void CARLSession::_bind_methods() {
	ClassDB::bind_method(D_METHOD("initialize", "single_threaded"), &CARLSession::initialize, DEFVAL(false));
	ClassDB::bind_method(D_METHOD("is_single_threaded"), &CARLSession::is_single_threaded);
	ClassDB::bind_method(D_METHOD("set_normalize_input_callback", "normalize_input_callback"), &CARLSession::set_normalize_input_callback);
	ClassDB::bind_method(D_METHOD("get_normalize_input_callback"), &CARLSession::get_normalize_input_callback);
	ClassDB::bind_method(D_METHOD("capture_input"), &CARLSession::capture_input);
	ClassDB::bind_method(D_METHOD("capture_input_from", "hmd_tracker", "left_hand_tracker", "right_hand_tracker"), &CARLSession::capture_input_from);
	ClassDB::bind_method(D_METHOD("add_input", "input_sample"), &CARLSession::add_input);
	ClassDB::bind_method(D_METHOD("process"), &CARLSession::process);
	ClassDB::bind_method(D_METHOD("create_recognizer", "definition"), &CARLSession::create_recognizer);

	ClassDB::bind_static_method("CARLSession", D_METHOD("normalize_input_y_axis_rotation", "input_sample"), &CARLSession::normalize_input_y_axis_rotation);

	ADD_PROPERTY(PropertyInfo(Variant::CALLABLE, "normalize_input_callback"), "set_normalize_input_callback", "get_normalize_input_callback");
}

void CARLSession::_log_message(const String &p_message) {
	// @todo Should we have a signal?
	print_line(p_message);
}

void CARLSession::initialize(bool p_single_threaded) {
	ERR_FAIL_COND_MSG(carl_session != nullptr, "CARLSession is already initialized");

	single_threaded = p_single_threaded;
	carl_session = new carl::Session(p_single_threaded);
	session_start = Time::get_singleton()->get_ticks_usec();

	carl_session->setLogger([this](std::string p_message) {
		// Use call_deferred() to ensure it's called on the correct thread.
		callable_mp(this, &CARLSession::_log_message).bind(String(p_message.c_str())).call_deferred();
	});
}

void CARLSession::set_normalize_input_callback(const Callable &p_normalize_callback) {
	normalize_input_callback = p_normalize_callback;
}

Callable CARLSession::get_normalize_input_callback() const {
	return normalize_input_callback;
}

Ref<CARLInputSample> CARLSession::capture_input() {
	XRServer *xr_server = XRServer::get_singleton();
	ERR_FAIL_NULL_V(xr_server, Ref<CARLInputSample>());

	Ref<XRPositionalTracker> hmd_tracker = xr_server->get_tracker("head");
	Ref<XRHandTracker> left_hand = xr_server->get_tracker("/user/hand_tracker/left");
	Ref<XRHandTracker> right_hand = xr_server->get_tracker("/user/hand_tracker/right");

	return capture_input_from(hmd_tracker, left_hand, right_hand);
}

Ref<CARLInputSample> CARLSession::capture_input_from(const Ref<XRPositionalTracker> &p_hmd_tracker, const Ref<XRHandTracker> &p_left_hand_tracker, const Ref<XRHandTracker> &p_right_hand_tracker) {
	Ref<CARLInputSample> input_sample;
	input_sample.instantiate();

	if (p_hmd_tracker.is_valid()) {
		input_sample->set_hmd_pose(p_hmd_tracker->get_pose("default")->get_transform());
	} else {
		return Ref<CARLInputSample>();
	}

	if (p_left_hand_tracker.is_valid() && p_left_hand_tracker->get_has_tracking_data()) {
		input_sample->populate_from_hand_tracker(p_left_hand_tracker);

		prev_data[0].wrist_pose = input_sample->get_left_wrist_pose();
		prev_data[0].joint_poses = input_sample->get_left_hand_joint_poses().duplicate();
		prev_data[0].valid = true;
	} else {
		if (!prev_data[0].valid) {
			return Ref<CARLInputSample>();
		}
		input_sample->set_left_wrist_pose(prev_data[0].wrist_pose);
		input_sample->set_left_hand_joint_poses(prev_data[0].joint_poses.duplicate());
	}

	if (p_right_hand_tracker.is_valid() && p_right_hand_tracker->get_has_tracking_data()) {
		input_sample->populate_from_hand_tracker(p_right_hand_tracker);

		prev_data[1].wrist_pose = input_sample->get_right_wrist_pose();
		prev_data[1].joint_poses = input_sample->get_right_hand_joint_poses().duplicate();
		prev_data[1].valid = true;
	} else {
		if (!prev_data[1].valid) {
			return Ref<CARLInputSample>();
		}
		input_sample->set_right_wrist_pose(prev_data[1].wrist_pose);
		input_sample->set_right_hand_joint_poses(prev_data[1].joint_poses.duplicate());
	}

	add_input(input_sample);

	return input_sample;
}

void CARLSession::add_input(const Ref<CARLInputSample> &p_input_sample) {
	ERR_FAIL_COND_MSG(carl_session == nullptr, "CARLSession must be initialized");
	ERR_FAIL_COND(p_input_sample.is_null());

	if (normalize_input_callback.is_valid()) {
		normalize_input_callback.call(p_input_sample);
	}

	double timestamp = double(Time::get_singleton()->get_ticks_usec() - session_start) / 1000000.0;
	p_input_sample->set_timestamp(timestamp);

	carl_session->addInput(p_input_sample->get_carl_object());
}

void CARLSession::process() {
	ERR_FAIL_COND_MSG(carl_session == nullptr, "CARLSession must be initialized");

	carl_session->tickCallbacks(arcana::cancellation::none());
}

Ref<CARLRecognizer> CARLSession::create_recognizer(const Ref<CARLDefinition> &p_definition) {
	Ref<CARLRecognizer> recognizer;
	recognizer.instantiate();
	recognizer->initialize(this, p_definition);
	return recognizer;
}

void CARLSession::normalize_input_y_axis_rotation(const Ref<CARLInputSample> &p_input_sample) {
	Transform3D hmd_pose = p_input_sample->get_hmd_pose();
	Vector3 rotation = hmd_pose.basis.get_euler(EULER_ORDER_YXZ);

	Transform3D hmd_unwind_transform;
	hmd_unwind_transform.basis = Basis(Vector3(0.0, 1.0, 0.0), rotation.y);
	hmd_unwind_transform.origin = Vector3(hmd_pose.origin.x, 0, hmd_pose.origin.y);
	hmd_unwind_transform.affine_invert();

	p_input_sample->set_hmd_pose(hmd_unwind_transform * hmd_pose);

	Transform3D left_wrist_pose = p_input_sample->get_left_wrist_pose();
	p_input_sample->set_left_wrist_pose(hmd_unwind_transform * left_wrist_pose);

	Transform3D right_wrist_pose = p_input_sample->get_right_wrist_pose();
	p_input_sample->set_right_wrist_pose(hmd_unwind_transform * right_wrist_pose);
}

CARLSession::CARLSession() {
	// Default to normalize input around the y axis.
	normalize_input_callback = callable_mp_static(&CARLSession::normalize_input_y_axis_rotation);
}

CARLSession::~CARLSession() {
	if (carl_session) {
		carl_session->tickCallbacks(arcana::cancellation::none());
		delete carl_session;
	}
}
