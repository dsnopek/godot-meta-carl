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

#include "carl_recognizer.h"

#include <arcana/threading/task.h>
#include <godot_cpp/core/mutex_lock.hpp>

#include "carl_session.h"
#include "carl_definition.h"

void CARLRecognizer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("set_sensitivity", "sensitivity"), &CARLRecognizer::set_sensitivity);
	ClassDB::bind_method(D_METHOD("get_sensitivity"), &CARLRecognizer::get_sensitivity);

	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "sensitivity"), "set_sensitivity", "get_sensitivity");

	ClassDB::bind_method(D_METHOD("is_ready"), &CARLRecognizer::is_ready);
	ClassDB::bind_method(D_METHOD("get_current_score"), &CARLRecognizer::get_current_score);

	ADD_SIGNAL(MethodInfo("ready"));
}

bool CARLRecognizer::is_ready() const {
	mutex->lock();
	bool ready = static_cast<bool>(carl_recognizer);
	mutex->unlock();

	return ready;
}

double CARLRecognizer::get_current_score() const {
	if (is_ready()) {
		return carl_recognizer->currentScore();
	}
	return 0.0;
}

void CARLRecognizer::set_sensitivity(double p_sensitivity) {
	sensitivity = p_sensitivity;
	if (is_ready()) {
		carl_recognizer->setSensitivity(p_sensitivity);
	}
}

double CARLRecognizer::get_sensitivity() const {
	return sensitivity;
}

void CARLRecognizer::initialize(const Ref<CARLSession> &p_session, const Ref<CARLDefinition> &p_definition) {
	session = p_session;
	sensitivity = p_definition->get_default_sensitivity();
	carl_definition = p_definition->create_carl_definition();

	// Schedule the creation of the recognizer.
	Ref<CARLRecognizer> self = this;
	carl::Session *carl_session = session->get_carl_session();
	arcana::make_task(carl_session->processingScheduler(), arcana::cancellation::none(), [carl_session, carl_definition = this->carl_definition]() {
		return new carl::action::Recognizer(*carl_session, *carl_definition);
	}).then(carl_session->callbackScheduler(), arcana::cancellation::none(), [self](carl::action::Recognizer *carl_recognizer) {
		self->_set_carl_recognizer(carl_recognizer);
		self->emit_signal("ready");
	});
}

void CARLRecognizer::_set_carl_recognizer(carl::action::Recognizer *p_carl_recognizer) {
	mutex->lock();
	carl_recognizer = p_carl_recognizer;
	carl_recognizer->setSensitivity(sensitivity);
	mutex->unlock();
}

CARLRecognizer::CARLRecognizer() {
	mutex.instantiate();
}

CARLRecognizer::~CARLRecognizer() {
	if (is_ready()) {
		carl::Session *carl_session = session->get_carl_session();
		arcana::make_task(carl_session->processingScheduler(), arcana::cancellation::none(), [carl_recognizer = this->carl_recognizer, carl_definition = this->carl_definition]() {
			delete carl_recognizer;
			delete carl_definition;
		});
	}
}
