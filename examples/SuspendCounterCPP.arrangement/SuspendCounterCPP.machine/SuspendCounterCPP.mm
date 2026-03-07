//
// SuspendCounterCPP.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "SuspendCounterCPP_Includes.h"
#include "SuspendCounterCPP.h"
#include "State_InitialPseudoState.h"
#include "State_Initial.h"
#include "State_Suspend_Counter.h"
#include "State_Resume_Counter.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	SuspendCounterCPP *CLM_Create_SuspendCounterCPP(int mid, const char *name)
	{
		return new SuspendCounterCPP(mid, name);
	}
}

SuspendCounterCPP::SuspendCounterCPP(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMSuspendCounterCPP::State::InitialPseudoState;
	_states[1] = new FSMSuspendCounterCPP::State::Initial;
	_states[2] = new FSMSuspendCounterCPP::State::Suspend_Counter;
	_states[3] = new FSMSuspendCounterCPP::State::Resume_Counter;

	setInitialState(_states[0]);            // set initial state
}

SuspendCounterCPP::~SuspendCounterCPP()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
	delete _states[3];
}