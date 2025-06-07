//
// State_YellowRed.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "TrafficLight_Includes.h"
#include "TrafficLight.h"
#include "State_YellowRed.h"

#include "State_YellowRed_Includes.h"

using namespace FSM;
using namespace CLM;
using namespace FSMTrafficLight;
using namespace State;

YellowRed::YellowRed(const char *name): CLState(name, *new YellowRed::OnEntry, *new YellowRed::OnExit, *new YellowRed::Internal)
{
	_transitions[0] = new Transition_0();
}

YellowRed::~YellowRed()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();

	delete _transitions[0];
}

void YellowRed::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_YellowRed_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_YellowRed_FuncRefs.mm"
#	include "State_YellowRed_OnEntry.mm"
}

void YellowRed::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_YellowRed_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_YellowRed_FuncRefs.mm"
#	include "State_YellowRed_OnExit.mm"
}

void YellowRed::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_YellowRed_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_YellowRed_FuncRefs.mm"
#	include "State_YellowRed_Internal.mm"
}

bool YellowRed::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "TrafficLight_VarRefs.mm"
#	include "State_YellowRed_VarRefs.mm"
#	include "TrafficLight_FuncRefs.mm"
#	include "State_YellowRed_FuncRefs.mm"

	return
	(
#		include "State_YellowRed_Transition_0.expr"
	);
}
