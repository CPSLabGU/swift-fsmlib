//
// Machine2.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Machine2_Includes.h"
#include "Machine2.h"

#include "State_InitialPseudoState.h"
#include "State_Initial.h"
#include "State_State_2.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	Machine2 *CLM_Create_Machine2(int mid, const char *name)
	{
		return new Machine2(mid, name);
	}
}

Machine2::Machine2(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMMachine2::State::InitialPseudoState;
	_states[1] = new FSMMachine2::State::Initial;
	_states[2] = new FSMMachine2::State::State_2;

	setInitialState(_states[0]);            // set initial state
}

Machine2::~Machine2()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
}
