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

#include "carl_recorder.h"

#include <godot_cpp/classes/time.hpp>

void CARLRecorder::_bind_methods() {
	ClassDB::bind_method(D_METHOD("start_recording", "max_seconds", "enabled_poses"), &CARLRecorder::start_recording);
	ClassDB::bind_method(D_METHOD("is_recording"), &CARLRecorder::is_recording);
	ClassDB::bind_method(D_METHOD("set_normalize_input_callback", "normalize_input_callback"), &CARLRecorder::set_normalize_input_callback);
	ClassDB::bind_method(D_METHOD("get_normalize_input_callback"), &CARLRecorder::get_normalize_input_callback);
	ClassDB::bind_method(D_METHOD("add_input", "input_sample"), &CARLRecorder::add_input);
	ClassDB::bind_method(D_METHOD("capture_input"), &CARLRecorder::capture_input);
	ClassDB::bind_method(D_METHOD("capture_input_from", "hmd_tracker", "left_hand_tracker", "right_hand_tracker"), &CARLRecorder::capture_input_from);
	ClassDB::bind_method(D_METHOD("finish_recording"), &CARLRecorder::finish_recording);

	ADD_PROPERTY(PropertyInfo(Variant::CALLABLE, "normalize_input_callback"), "set_normalize_input_callback", "get_normalize_input_callback");
}

void CARLRecorder::start_recording(uint64_t p_max_seconds, BitField<CARLInputSample::Pose> p_enabled_poses) {
	ERR_FAIL_COND(carl_ipr != nullptr);
	carl_ipr = new carl::action::InProgressRecording(p_max_seconds);
	capture_helper = memnew(CARLCaptureHelper(p_enabled_poses));
	recording_start = Time::get_singleton()->get_ticks_usec();
}

bool CARLRecorder::is_recording() const {
	return carl_ipr != nullptr;
}

void CARLRecorder::set_normalize_input_callback(const Callable &p_normalize_callback) {
	normalize_input_callback = p_normalize_callback;
}

Callable CARLRecorder::get_normalize_input_callback() const {
	return normalize_input_callback;
}

Ref<CARLInputSample> CARLRecorder::capture_input() {
	ERR_FAIL_NULL_V_MSG(carl_ipr, Ref<CARLInputSample>(), "CARLRecorder must be started");

	Ref<CARLInputSample> input_sample = capture_helper->capture_input();
	if (input_sample.is_null()) {
		return input_sample;
	}

	add_input(input_sample);
	return input_sample;
}

Ref<CARLInputSample> CARLRecorder::capture_input_from(const Ref<XRPositionalTracker> &p_hmd_tracker, const Ref<XRHandTracker> &p_left_hand_tracker, const Ref<XRHandTracker> &p_right_hand_tracker) {
	ERR_FAIL_NULL_V_MSG(carl_ipr, Ref<CARLInputSample>(), "CARLRecorder must be started");

	Ref<CARLInputSample> input_sample = capture_helper->capture_input_from(p_hmd_tracker, p_left_hand_tracker, p_right_hand_tracker);
	if (input_sample.is_null()) {
		return input_sample;
	}

	add_input(input_sample);
	return input_sample;
}

void CARLRecorder::add_input(const Ref<CARLInputSample> &p_input_sample) {
	ERR_FAIL_NULL_MSG(carl_ipr, "CARLRecorder must be started");
	ERR_FAIL_COND(p_input_sample.is_null());

	if (normalize_input_callback.is_valid()) {
		normalize_input_callback.call(p_input_sample);
	}

	double timestamp = double(Time::get_singleton()->get_ticks_usec() - recording_start) / 1000000.0;
	p_input_sample->set_timestamp(timestamp);

	carl_ipr->addSample(p_input_sample->get_carl_object());
}

Ref<CARLRecording> CARLRecorder::finish_recording() {
	ERR_FAIL_NULL_V_MSG(carl_ipr, Ref<CARLRecording>(), "CARLRecorder must be started");

	carl::action::Recording *carl_recording = new carl::action::Recording(std::move(*carl_ipr));
	Ref<CARLRecording> recording = Ref<CARLRecording>(memnew(CARLRecording(carl_recording)));

	delete carl_ipr;
	carl_ipr = nullptr;

	memdelete(capture_helper);
	capture_helper = nullptr;

	return recording;
}

CARLRecorder::CARLRecorder() {
}

CARLRecorder::~CARLRecorder() {
	if (carl_ipr) {
		delete carl_ipr;
	}
	if (capture_helper) {
		memdelete(capture_helper);
	}
}
