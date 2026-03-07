//
// State_CountUp.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Counter_Includes.h"
#include "Counter.h"
#include "State_CountUp.h"

#include "State_CountUp_Includes.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

using namespace FSM;
using namespace CLM;
using namespace FSMCounter;
using namespace State;

CountUp::CountUp(const char *name): CLState(name, *new CountUp::OnEntry, *new CountUp::OnExit, *new CountUp::Internal, NULLPTR, new CountUp::OnSuspend, new CountUp::OnResume)
{
	_transitions[0] = new Transition_0();
}

CountUp::~CountUp()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();
	delete onSuspendAction();
	delete onResumeAction();

	delete _transitions[0];
}

void CountUp::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_CountUp_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_CountUp_FuncRefs.mm"
#	include "State_CountUp_OnEntry.mm"
}

void CountUp::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_CountUp_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_CountUp_FuncRefs.mm"
#	include "State_CountUp_OnExit.mm"
}

void CountUp::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_CountUp_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_CountUp_FuncRefs.mm"
#	include "State_CountUp_Internal.mm"
}

void CountUp::OnSuspend::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_CountUp_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_CountUp_FuncRefs.mm"
#	include "State_CountUp_OnSuspend.mm"
}

void CountUp::OnResume::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_CountUp_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_CountUp_FuncRefs.mm"
#	include "State_CountUp_OnResume.mm"
}

bool CountUp::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_CountUp_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_CountUp_FuncRefs.mm"

	return
	(
#		include "State_CountUp_Transition_0.expr"
	);
}
