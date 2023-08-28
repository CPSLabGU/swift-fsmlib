//
// SuspendCounter.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "SuspendCounter_Includes.h"
#include "SuspendCounter.h"

#include "State_InitialPseudoState.h"
#include "State_Initial.h"
#include "State_Suspend_Counter.h"
#include "State_Resume_Counter.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	SuspendCounter *CLM_Create_SuspendCounter(int mid, const char *name)
	{
		return new SuspendCounter(mid, name);
	}
}

SuspendCounter::SuspendCounter(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMSuspendCounter::State::InitialPseudoState;
	_states[1] = new FSMSuspendCounter::State::Initial;
	_states[2] = new FSMSuspendCounter::State::Suspend_Counter;
	_states[3] = new FSMSuspendCounter::State::Resume_Counter;

	setInitialState(_states[0]);            // set initial state
}

SuspendCounter::~SuspendCounter()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
	delete _states[3];
}
