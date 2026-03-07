//
// State_Green.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "TrafficLight_Includes.h"
#include "TrafficLight.h"
#include "State_Green.h"

#include "State_Green_Includes.h"

using namespace FSM;
using namespace CLM;
using namespace FSMTrafficLight;
using namespace State;

Green::Green(const char *name): CLState(name, *new Green::OnEntry, *new Green::OnExit, *new Green::Internal)
{
	_transitions[0] = new Transition_0();
}

Green::~Green()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();

	delete _transitions[0];
}

void Green::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Green_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Green_FuncRefs.mm"
#	include "State_Green_OnEntry.mm"
}

void Green::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Green_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Green_FuncRefs.mm"
#	include "State_Green_OnExit.mm"
}

void Green::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Green_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Green_FuncRefs.mm"
#	include "State_Green_Internal.mm"
}

bool Green::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_Green_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_Green_FuncRefs.mm"

	return
	(
#		include "State_Green_Transition_0.expr"
	);
}
