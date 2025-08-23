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

#include "carl_example.h"

#include "carl_recording.h"

#include <algorithm>

void CARLExample::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_recording", "recording"), &CARLExample::set_recording);
	ClassDB::bind_method(D_METHOD("get_recording"), &CARLExample::get_recording);

	ClassDB::bind_method(D_METHOD("set_start_timestamp", "timestamp"), &CARLExample::set_start_timestamp);
	ClassDB::bind_method(D_METHOD("get_start_timestamp"), &CARLExample::get_start_timestamp);

	ClassDB::bind_method(D_METHOD("set_end_timestamp", "timestamp"), &CARLExample::set_end_timestamp);
	ClassDB::bind_method(D_METHOD("get_end_timestamp"), &CARLExample::get_end_timestamp);

	ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "start_timestamp", PROPERTY_HINT_RESOURCE_TYPE, "CARLRecording"), "set_recording", "get_recording");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "start_timestamp"), "set_start_timestamp", "get_start_timestamp");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "end_timestamp"), "set_end_timestamp", "get_end_timestamp");
}

void CARLExample::set_recording(const Ref<CARLRecording> &p_recording) {
	recording = p_recording;
	if (recording.is_valid()) {
		start_timestamp = std::max(recording->get_start_timestamp(), start_timestamp);
		end_timestamp = std::min(recording->get_end_timestamp(), end_timestamp);
	}
}

Ref<CARLRecording> CARLExample::get_recording() const {
	return recording;
}

void CARLExample::set_start_timestamp(double p_timestamp) {
	if (recording.is_valid()) {
		start_timestamp = std::max(recording->get_start_timestamp(), p_timestamp);
	} else {
		start_timestamp = p_timestamp;
	}
}

double CARLExample::get_start_timestamp() const {
	return start_timestamp;
}

void CARLExample::set_end_timestamp(double p_timestamp) {
	if (recording.is_valid()) {
		end_timestamp = std::max(recording->get_end_timestamp(), p_timestamp);
	} else {
		end_timestamp = p_timestamp;
	}
}

double CARLExample::get_end_timestamp() const {
	return end_timestamp;
}
