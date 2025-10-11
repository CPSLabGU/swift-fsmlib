//
// Suspend.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Suspend_Includes.h"
#include "Suspend.h"

#include "State_InitialPseudoState.h"
#include "State_Initial.h"
#include "State_Suspend_Counter.h"
#include "State_Resume_Counter.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	Suspend *CLM_Create_Suspend(int mid, const char *name)
	{
		return new Suspend(mid, name);
	}
}

Suspend::Suspend(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMSuspend::State::InitialPseudoState;
	_states[1] = new FSMSuspend::State::Initial;
	_states[2] = new FSMSuspend::State::Suspend_Counter;
	_states[3] = new FSMSuspend::State::Resume_Counter;

	setInitialState(_states[0]);            // set initial state
}

Suspend::~Suspend()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
	delete _states[3];
}
