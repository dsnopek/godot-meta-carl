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

#include "carl_definition.h"

#include "carl_example.h"
#include "carl_recording.h"

void CARLDefinition::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_action_type", "action_type"), &CARLDefinition::set_action_type);
	ClassDB::bind_method(D_METHOD("get_action_type"), &CARLDefinition::get_action_type);

	ClassDB::bind_method(D_METHOD("set_examples", "examples"), &CARLDefinition::set_examples);
	ClassDB::bind_method(D_METHOD("get_examples"), &CARLDefinition::get_examples);

	ClassDB::bind_method(D_METHOD("set_counter_examples", "examples"), &CARLDefinition::set_counter_examples);
	ClassDB::bind_method(D_METHOD("get_counter_examples"), &CARLDefinition::get_counter_examples);

	ADD_PROPERTY(PropertyInfo(Variant::INT, "action_type", PROPERTY_HINT_ENUM, "Left Hand Pose,Left Hand Gesture,Right Hand Pose,Right Hand Gesture,Two Hand Gesture,Left Controller Gesture,Right Controller Gesture,Two Controller Gesture,Left Wrist Trajectory,Right Wrist Trajectory,Left Hand Shape,Right Hand Shape"), "get_action_type", "set_action_type");
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "examples", PROPERTY_HINT_ARRAY_TYPE, vformat("%d/%d:%s", Variant::OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "CARLExample")), "set_examples", "get_examples");
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "counter_examples", PROPERTY_HINT_ARRAY_TYPE, vformat("%d/%d:%s", Variant::OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "CARLExample")), "set_counter_examples", "get_counter_examples");
}

void CARLDefinition::set_action_type(ActionType p_action_type) {
	action_type = p_action_type;
}

CARLDefinition::ActionType CARLDefinition::get_action_type() const {
	return action_type;
}

void CARLDefinition::set_examples(const TypedArray<CARLExample> &p_examples) {
	examples = p_examples;
}

TypedArray<CARLExample> CARLDefinition::get_examples() const {
	return examples;
}

void CARLDefinition::set_counter_examples(const TypedArray<CARLExample> &p_examples) {
	counter_examples = p_examples;
}

TypedArray<CARLExample> CARLDefinition::get_counter_examples() const {
	return counter_examples;
}
