//
// Machine1.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Machine1_Includes.h"
#include "Machine1.h"

#include "State_InitialPseudoState.h"
#include "State_Initial.h"
#include "State_State_2.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	Machine1 *CLM_Create_Machine1(int mid, const char *name)
	{
		return new Machine1(mid, name);
	}
}

Machine1::Machine1(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMMachine1::State::InitialPseudoState;
	_states[1] = new FSMMachine1::State::Initial;
	_states[2] = new FSMMachine1::State::State_2;

	setInitialState(_states[0]);            // set initial state
}

Machine1::~Machine1()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
}
