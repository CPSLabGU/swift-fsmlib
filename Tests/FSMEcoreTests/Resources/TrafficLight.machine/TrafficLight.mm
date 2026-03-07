//
// TrafficLight.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "TrafficLight_Includes.h"
#include "TrafficLight.h"

#include "State_InitialPseudoState.h"
#include "State_Red.h"
#include "State_Yellow.h"
#include "State_Green.h"
#include "State_YellowRed.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	TrafficLight *CLM_Create_TrafficLight(int mid, const char *name)
	{
		return new TrafficLight(mid, name);
	}
}

TrafficLight::TrafficLight(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMTrafficLight::State::InitialPseudoState;
	_states[1] = new FSMTrafficLight::State::Red;
	_states[2] = new FSMTrafficLight::State::Yellow;
	_states[3] = new FSMTrafficLight::State::Green;
	_states[4] = new FSMTrafficLight::State::YellowRed;

	setInitialState(_states[0]);            // set initial state
}

TrafficLight::~TrafficLight()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
	delete _states[3];
	delete _states[4];
}
