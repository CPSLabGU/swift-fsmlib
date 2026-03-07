//
// State_Red.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "TrafficLight_Includes.h"
#include "TrafficLight.h"
#include "State_Red.h"

#include "State_Red_Includes.h"

using namespace FSM;
using namespace CLM;
using namespace FSMTrafficLight;
using namespace State;

Red::Red(const char *name): CLState(name, *new Red::OnEntry, *new Red::OnExit, *new Red::Internal)
{
	_transitions[0] = new Transition_0();
}

Red::~Red()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();

	delete _transitions[0];
}

void Red::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Red_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Red_FuncRefs.mm"
#	include "State_Red_OnEntry.mm"
}

void Red::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Red_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Red_FuncRefs.mm"
#	include "State_Red_OnExit.mm"
}

void Red::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Red_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Red_FuncRefs.mm"
#	include "State_Red_Internal.mm"
}

bool Red::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Red_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Red_FuncRefs.mm"

	return
	(
#		include "State_Red_Transition_0.expr"
	);
}
