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

#include <carl/Carl.h>

#include "carl_input_sample.h"
#include "carl_recording.h"

using namespace godot;

namespace godot {
class XRPositionalTracker;
}

class CARLRecorder : public RefCounted {
	GDCLASS(CARLRecorder, RefCounted);

	carl::action::InProgressRecording *carl_ipr = nullptr;

protected:
	static void _bind_methods();

public:
	void start_recording(uint64_t p_max_seconds);
	bool is_recording() const;

	void record_input_sample(const Ref<CARLInputSample> &p_input_sample);
	// @todo Add some more direct recording methods
	//void record_trackers(double p_timestamp, const Ref<XRPositionalTracker> &p_hmd_tracker, const Ref<XRHandTracker> &p_left_hand, const Ref<XRHandTracker> &p_right_hand, BitField<CARLInputSample> p_enabled_poses);

	Ref<CARLRecording> finish_recording();

	CARLRecorder();
	~CARLRecorder();
};
