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

#include <carl/Carl.h>

using namespace godot;

class CARLInputSample;
class CARLDefinition;
class CARLRecognizer;

class CARLSession : public RefCounted {
	GDCLASS(CARLSession, RefCounted);

	carl::Session *carl_session = nullptr;
	bool single_threaded = false;
	uint64_t session_start = 0;
	Callable normalize_callback;

	struct PreviousData {
		bool valid = false;
		Transform3D wrist_pose;
		TypedArray<Transform3D> joint_poses;
	};
	PreviousData prev_data[2];

	void _log_message(const String &p_message);

protected:
	static void _bind_methods();

public:
	void initialize(bool p_single_threaded = false);

	bool is_single_threaded() const { return single_threaded; }

	void set_input_normalize_callback(const Callable &p_normalize_callback);
	Callable get_input_normalize_callback() const;

	Ref<CARLInputSample> capture_input();
	Ref<CARLInputSample> capture_input_from(const Ref<XRPositionalTracker> &p_hmd_tracker, const Ref<XRHandTracker> &p_left_hand_tracker, const Ref<XRHandTracker> &p_right_hand_tracker);
	void add_input(const Ref<CARLInputSample> &p_input_sample);
	void process();

	Ref<CARLRecognizer> create_recognizer(const Ref<CARLDefinition> &p_definition);

	carl::Session *get_carl_session() const { return carl_session; }

	~CARLSession();
};
