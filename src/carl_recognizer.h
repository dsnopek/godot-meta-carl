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
#include <godot_cpp/core/mutex_lock.hpp>

#include <carl/Carl.h>

using namespace godot;

class CARLSession;
class CARLDefinition;

class CARLRecognizer : public RefCounted {
	GDCLASS(CARLRecognizer, RefCounted);

	friend class CARLSession;

	Ref<CARLSession> session;
	double sensitivity = 1.0;

	mutable Ref<Mutex> mutex;

	carl::action::Recognizer *carl_recognizer = nullptr;
	carl::action::Definition *carl_definition = nullptr;

protected:
	static void _bind_methods();

	void initialize(const Ref<CARLSession> &p_session, const Ref<CARLDefinition> &p_definition);
	void _set_carl_recognizer(carl::action::Recognizer *p_carl_recognizer);

public:
	bool is_ready() const;

	void set_sensitivity(double p_sensitivity);
	double get_sensitivity() const;

	double get_current_score() const;

	CARLRecognizer();
	~CARLRecognizer();
};
