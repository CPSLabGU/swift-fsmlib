//
// Counter.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Counter_Includes.h"
#include "Counter.h"

#include "State_InitialPseudoState.h"
#include "State_Initial.h"
#include "State_CountUp.h"
#include "State_Print.h"
#include "State_SUSPENDED.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	Counter *CLM_Create_Counter(int mid, const char *name)
	{
		return new Counter(mid, name);
	}
}

Counter::Counter(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMCounter::State::InitialPseudoState;
	_states[1] = new FSMCounter::State::Initial;
	_states[2] = new FSMCounter::State::CountUp;
	_states[3] = new FSMCounter::State::Print;
	_states[4] = new FSMCounter::State::SUSPENDED;

	setSuspendState(_states[4]);            // set suspend state
	setInitialState(_states[0]);            // set initial state
}

Counter::~Counter()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
	delete _states[3];
	delete _states[4];
}
