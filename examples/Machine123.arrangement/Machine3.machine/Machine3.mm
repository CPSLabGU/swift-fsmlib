//
// Machine3.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Machine3_Includes.h"
#include "Machine3.h"

#include "State_InitialPseudoState.h"
#include "State_Initial.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	Machine3 *CLM_Create_Machine3(int mid, const char *name)
	{
		return new Machine3(mid, name);
	}
}

Machine3::Machine3(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMMachine3::State::InitialPseudoState;
	_states[1] = new FSMMachine3::State::Initial;

	setInitialState(_states[0]);            // set initial state
}

Machine3::~Machine3()
{
	delete _states[0];
	delete _states[1];
}
