//
// State_Yellow.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "TrafficLight_Includes.h"
#include "TrafficLight.h"
#include "State_Yellow.h"

#include "State_Yellow_Includes.h"

using namespace FSM;
using namespace CLM;
using namespace FSMTrafficLight;
using namespace State;

Yellow::Yellow(const char *name): CLState(name, *new Yellow::OnEntry, *new Yellow::OnExit, *new Yellow::Internal)
{
	_transitions[0] = new Transition_0();
}

Yellow::~Yellow()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();

	delete _transitions[0];
}

void Yellow::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Yellow_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Yellow_FuncRefs.mm"
#	include "State_Yellow_OnEntry.mm"
}

void Yellow::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Yellow_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Yellow_FuncRefs.mm"
#	include "State_Yellow_OnExit.mm"
}

void Yellow::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Yellow_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Yellow_FuncRefs.mm"
#	include "State_Yellow_Internal.mm"
}

bool Yellow::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Yellow_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Yellow_FuncRefs.mm"

	return
	(
#		include "State_Yellow_Transition_0.expr"
	);
}
