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
	ClassDB::bind_method(D_METHOD("_set_data", "data"), &CARLRecording::_set_data);
	ClassDB::bind_method(D_METHOD("_get_data"), &CARLRecording::_get_data);

	ClassDB::bind_method(D_METHOD("get_start_timestamp"), &CARLRecording::get_start_timestamp);
	ClassDB::bind_method(D_METHOD("get_end_timestamp"), &CARLRecording::get_end_timestamp);
	ClassDB::bind_method(D_METHOD("inspect", "timestamp"), &CARLRecording::inspect);

	ClassDB::bind_method(D_METHOD("serialize"), &CARLRecording::serialize);
	ClassDB::bind_static_method("CARLRecording", D_METHOD("deserialize", "data"), &CARLRecording::deserialize);

	ADD_PROPERTY(PropertyInfo(Variant::PACKED_BYTE_ARRAY, "data", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "_set_data", "_get_data");
}

void CARLRecording::_set_data(const PackedByteArray &p_data) {
	if (carl_recording) {
		delete carl_recording;
	}

	data = p_data;

	carl::Deserialization deserialization{ p_data.ptr() };
	carl_recording = new carl::action::Recording(deserialization);
}

PackedByteArray CARLRecording::_get_data() const {
	if (!carl_recording) {
		// Not an error because this will be called by the editor on empty objects.
		return PackedByteArray();
	}
	if (data.size() > 0) {
		return data;
	}

	std::vector<uint8_t> bytes;
	carl::Serialization serialization{ bytes };
	carl_recording->serialize(serialization);

	PackedByteArray new_data;
	new_data.resize(bytes.size());
	memcpy(new_data.ptrw(), bytes.data(), bytes.size());
	data = new_data;

	return data;
}

PackedByteArray CARLRecording::serialize() const {
	return _get_data();
}

Ref<CARLRecording> CARLRecording::deserialize(const PackedByteArray &p_data) {
	Ref<CARLRecording> ret;
	ret.instantiate();
	ret->_set_data(p_data);
	return ret;
}

double CARLRecording::get_start_timestamp() const {
	if (carl_recording) {
		return carl_recording->getInspector().startTimestamp();
	}
	return 0;
}

double CARLRecording::get_end_timestamp() const {
	if (carl_recording) {
		return carl_recording->getInspector().endTimestamp();
	}
	return 0;
}

Ref<CARLInputSample> CARLRecording::inspect(double p_timestamp) const {
	if (carl_recording) {
		const carl::InputSample &is = carl_recording->getInspector().inspect(p_timestamp);
		return Ref<CARLInputSample>(memnew(CARLInputSample(is)));
	}
	return Ref<CARLInputSample>();
}

CARLRecording::CARLRecording() {
}

CARLRecording::CARLRecording(carl::action::Recording *p_carl_recording) {
	carl_recording = p_carl_recording;
}

CARLRecording::~CARLRecording() {
	if (carl_recording) {
		delete carl_recording;
	}
}
