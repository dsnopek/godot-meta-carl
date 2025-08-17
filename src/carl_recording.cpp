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

#include "carl_recording.h"

void CARLRecording::_bind_methods() {
}

void CARLRecording::_set_data(const PackedByteArray &p_data) {
}

PackedByteArray CARLRecording::serialize() const {
	return PackedByteArray();
}

Ref<CARLRecording> CARLRecording::deserialize(const PackedByteArray &p_data) {
	return Ref<CARLRecording>();
}

double CARLRecording::get_start_timestamp() const {
	return 0;
}

double CARLRecording::get_end_timestamp() const {
	return 0;
}

Ref<CARLInputSample> CARLRecording::inspect(double p_timestamp) const {
	return Ref<CARLInputSample>();
}

CARLRecording::CARLRecording() {
}

CARLRecording::CARLRecording(carl::action::Recording *p_carl_recording) {
}

CARLRecording::~CARLRecording() {
}
