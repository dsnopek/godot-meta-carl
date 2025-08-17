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

void CARLRecorder::_bind_methods() {
	ClassDB::bind_method(D_METHOD("start_recording", "max_seconds"), &CARLRecorder::start_recording);
	ClassDB::bind_method(D_METHOD("is_recording"), &CARLRecorder::is_recording);
	ClassDB::bind_method(D_METHOD("record_input_sample", "input_sample"), &CARLRecorder::record_input_sample);
	ClassDB::bind_method(D_METHOD("finish_recording"), &CARLRecorder::finish_recording);
}

void CARLRecorder::start_recording(uint64_t p_max_seconds) {
	ERR_FAIL_COND(carl_ipr != nullptr);
	carl_ipr = new carl::action::InProgressRecording(p_max_seconds);
}

bool CARLRecorder::is_recording() const {
	return carl_ipr != nullptr;
}

void CARLRecorder::record_input_sample(const Ref<CARLInputSample> &p_input_sample) {
	carl_ipr->addSample(p_input_sample->get_carl_object());
}

Ref<CARLRecording> CARLRecorder::finish_recording() {
	ERR_FAIL_NULL_V(carl_ipr, Ref<CARLRecording>());

	carl::action::Recording *carl_recording = new carl::action::Recording(std::move(*carl_ipr));
	Ref<CARLRecording> recording = Ref<CARLRecording>(memnew(CARLRecording(carl_recording)));

	delete carl_ipr;
	carl_ipr = nullptr;

	return recording;
}

CARLRecorder::CARLRecorder() {
}

CARLRecorder::~CARLRecorder() {
	if (carl_ipr) {
		delete carl_ipr;
	}
}
