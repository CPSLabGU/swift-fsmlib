//
// CounterCPP.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "CounterCPP_Includes.h"
#include "CounterCPP.h"

#include "State_InitialPseudoState.h"
#include "State_Initial.h"
#include "State_CountUp.h"
#include "State_Print.h"
#include "State_SUSPENDED.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	CounterCPP *CLM_Create_CounterCPP(int mid, const char *name)
	{
		return new CounterCPP(mid, name);
	}
}

CounterCPP::CounterCPP(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMCounterCPP::State::InitialPseudoState;
	_states[1] = new FSMCounterCPP::State::Initial;
	_states[2] = new FSMCounterCPP::State::CountUp;
	_states[3] = new FSMCounterCPP::State::Print;
	_states[4] = new FSMCounterCPP::State::SUSPENDED;

	setSuspendState(_states[4]);            // set suspend state
	setInitialState(_states[0]);            // set initial state
}

CounterCPP::~CounterCPP()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
	delete _states[3];
	delete _states[4];
}
