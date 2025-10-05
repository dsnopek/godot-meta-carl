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

#include <godot_cpp/classes/resource.hpp>

#include <carl/Carl.h>

using namespace godot;

class CARLExample;

class CARLDefinition : public Resource {
	GDCLASS(CARLDefinition, Resource);

public:
	enum ActionType {
		ACTION_LEFT_HAND_POSE,
		ACTION_LEFT_HAND_GESTURE,
		ACTION_RIGHT_HAND_POSE,
		ACTION_RIGHT_HAND_GESTURE,
		ACTION_TWO_HAND_GESTURE,
		ACTION_LEFT_CONTROLLER_GESTURE,
		ACTION_RIGHT_CONTROLLER_GESTURE,
		ACTION_TWO_CONTROLLER_GESTURE,
		ACTION_LEFT_WRIST_TRAJECTORY,
		ACTION_RIGHT_WRIST_TRAJECTORY,
		ACTION_LEFT_HAND_SHAPE,
		ACTION_RIGHT_HAND_SHAPE,
	};

private:
	ActionType action_type = ACTION_LEFT_HAND_POSE;
	TypedArray<CARLExample> examples;
	TypedArray<CARLExample> counter_examples;
	double default_sensitivity = 1.0;

protected:
	static void _bind_methods();

public:
	PackedByteArray serialize() const;

	void set_action_type(ActionType p_action_type);
	ActionType get_action_type() const;

	void set_examples(const TypedArray<CARLExample> &p_examples);
	TypedArray<CARLExample> get_examples() const;

	void set_counter_examples(const TypedArray<CARLExample> &p_examples);
	TypedArray<CARLExample> get_counter_examples() const;

	void set_default_sensitivity(double p_sensitivity);
	double get_default_sensitivity() const;

	void add_example(const Ref<CARLExample> &p_example);
	void add_counter_example(const Ref<CARLExample> &p_example);

	carl::action::Definition *create_carl_definition() const;
};

VARIANT_ENUM_CAST(CARLDefinition::ActionType);
