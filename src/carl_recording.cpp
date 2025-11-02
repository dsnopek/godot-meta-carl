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

#define BINARY_VERSION_MARKER 0xffffffffffffffffUL
#define BINARY_CURRENT_VERSION 2

void CARLRecording::_bind_methods() {
	ClassDB::bind_method(D_METHOD("_set_data", "data"), &CARLRecording::_set_data);
	ClassDB::bind_method(D_METHOD("_get_data"), &CARLRecording::_get_data);

	ClassDB::bind_method(D_METHOD("get_start_timestamp"), &CARLRecording::get_start_timestamp);
	ClassDB::bind_method(D_METHOD("get_end_timestamp"), &CARLRecording::get_end_timestamp);

	ClassDB::bind_method(D_METHOD("get_input_sample_count"), &CARLRecording::get_input_sample_count);

	ClassDB::bind_method(D_METHOD("inspect", "timestamp"), &CARLRecording::inspect);

	ClassDB::bind_method(D_METHOD("serialize"), &CARLRecording::serialize);
	ClassDB::bind_static_method("CARLRecording", D_METHOD("deserialize", "data"), &CARLRecording::deserialize);

	ADD_PROPERTY(PropertyInfo(Variant::PACKED_BYTE_ARRAY, "data", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE), "_set_data", "_get_data");

	ADD_PROPERTY(PropertyInfo(Variant::INT, "input_sample_count", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY), "", "get_input_sample_count");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "start_timestamp", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY), "", "get_start_timestamp");
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "end_timestamp", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY), "", "get_end_timestamp");
}

PackedByteArray CARLRecording::convert_from_version_0(const PackedByteArray &p_orig_data) {
	carl::Deserialization deserialization{ p_orig_data.ptr() };

	uint64_t count;
	deserialization >> count;

	std::vector<carl::InputSample> samples;
	samples.reserve(count);

	for (uint64_t idx = 0; idx < count; ++idx) {
		Ref<CARLInputSample> sample = CARLInputSample::deserialize_from_version_zero(deserialization);
		update_sample_from_version(sample, 0);
		samples.emplace_back(sample->get_carl_object());
	}

	std::vector<uint8_t> bytes;
	carl::Serialization serialization{ bytes };

	serialization << samples.size();
	for (uint64_t idx = 0; idx < count; ++idx) {
		samples[idx].serialize(serialization);
	}

	PackedByteArray new_data;
	new_data.resize(bytes.size() + 16);
	new_data.encode_u64(0, BINARY_VERSION_MARKER);
	new_data.encode_u64(8, BINARY_CURRENT_VERSION);
	memcpy(new_data.ptrw() + 16, bytes.data(), bytes.size());

	return new_data;
}

PackedByteArray CARLRecording::convert_from_version_1(const PackedByteArray &p_orig_data) {
	carl::Deserialization deserialization{ p_orig_data.ptr() + 16};

	uint64_t count;
	deserialization >> count;

	std::vector<carl::InputSample> samples;
	samples.reserve(count);

	for (uint64_t idx = 0; idx < count; ++idx) {
		carl::InputSample cis(deserialization);
		Ref<CARLInputSample> sample = Ref<CARLInputSample>(memnew(CARLInputSample(cis)));
		update_sample_from_version(sample, 1);
		samples.emplace_back(sample->get_carl_object());
	}

	std::vector<uint8_t> bytes;
	carl::Serialization serialization{ bytes };

	serialization << samples.size();
	for (uint64_t idx = 0; idx < count; ++idx) {
		samples[idx].serialize(serialization);
	}

	PackedByteArray new_data;
	new_data.resize(bytes.size() + 16);
	new_data.encode_u64(0, BINARY_VERSION_MARKER);
	new_data.encode_u64(8, BINARY_CURRENT_VERSION);
	memcpy(new_data.ptrw() + 16, bytes.data(), bytes.size());

	return new_data;
}

void CARLRecording::update_sample_from_version(const Ref<CARLInputSample> &p_input_sample, uint64_t p_version) {
	if (p_version < 2) {
		BitField<CARLInputSample::Pose> enabled_poses = p_input_sample->get_enabled_poses();

		if ((enabled_poses & CARLInputSample::POSE_LEFT_WRIST) && (enabled_poses & CARLInputSample::POSE_LEFT_JOINTS)) {
			Transform3D wrist_pose = p_input_sample->get_left_wrist_pose();
			TypedArray<Transform3D> joints = p_input_sample->get_left_hand_joint_poses();
			for (int i = 0; i < joints.size(); i++) {
				Transform3D joint = joints[i];
				joint = wrist_pose * joint;
				joints[i] = joint;
			}
			p_input_sample->set_left_hand_joint_poses(joints);
		}

		if ((enabled_poses & CARLInputSample::POSE_RIGHT_WRIST) && (enabled_poses & CARLInputSample::POSE_RIGHT_JOINTS)) {
			Transform3D wrist_pose = p_input_sample->get_right_wrist_pose();
			TypedArray<Transform3D> joints = p_input_sample->get_right_hand_joint_poses();
			for (int i = 0; i < joints.size(); i++) {
				Transform3D joint = joints[i];
				joint = wrist_pose * joint;
				joints[i] = joint;
			}
			p_input_sample->set_right_hand_joint_poses(joints);
		}
	}
}

void CARLRecording::_set_data(const PackedByteArray &p_data) {
	if (carl_recording) {
		delete carl_recording;
	}

	uint64_t version = 0;
	uint64_t version_marker = p_data.decode_u64(0);
	if (version_marker == BINARY_VERSION_MARKER) {
		version = p_data.decode_u64(8);
	}

	if (version > BINARY_CURRENT_VERSION) {
		ERR_PRINT(vformat("Unable to deserialize CARLInputSample with unknown version %d", version));
		return;
	}

	data = p_data;

	if (version == 0) {
		data = convert_from_version_0(data);
	} else if (version == 1) {
		data = convert_from_version_1(data);
	}

	if (data.size() < 16) {
		ERR_PRINT(vformat("Unable to deserialize CARLInputSample with only %d bytes of data", data.size()));
		data.clear();
		return;
	}

	carl::Deserialization deserialization{ data.ptr() + 16 };
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
	new_data.resize(bytes.size() + 16);
	new_data.encode_u64(0, BINARY_VERSION_MARKER);
	new_data.encode_u64(8, BINARY_CURRENT_VERSION);
	memcpy(new_data.ptrw() + 16, bytes.data(), bytes.size());
	data = new_data;

	return data;
}

PackedByteArray CARLRecording::serialize() const {
	ERR_FAIL_COND_V(!carl_recording, PackedByteArray());

	std::vector<uint8_t> bytes;
	carl::Serialization serialization{ bytes };
	carl_recording->serialize(serialization);

	PackedByteArray data;
	data.resize(bytes.size());
	memcpy(data.ptrw(), bytes.data(), bytes.size());
	return data;
}

Ref<CARLRecording> CARLRecording::deserialize(const PackedByteArray &p_data) {
	Ref<CARLRecording> ret;
	ret.instantiate();

	carl::Deserialization deserialization{ p_data.ptr() };
	ret->carl_recording = new carl::action::Recording(deserialization);

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

int CARLRecording::get_input_sample_count() const {
	if (carl_recording) {
		return carl_recording->getSamples().size();
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
