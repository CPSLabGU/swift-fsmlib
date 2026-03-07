//
// State_Suspend_Counter.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "SuspendCounter_Includes.h"
#include "SuspendCounter.h"
#include "State_Suspend_Counter.h"

#include "State_Suspend_Counter_Includes.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

using namespace FSM;
using namespace CLM;
using namespace FSMSuspendCounter;
using namespace State;

Suspend_Counter::Suspend_Counter(const char *name): CLState(name, *new Suspend_Counter::OnEntry, *new Suspend_Counter::OnExit, *new Suspend_Counter::Internal, NULLPTR, new Suspend_Counter::OnSuspend, new Suspend_Counter::OnResume)
{
	_transitions[0] = new Transition_0();
}

Suspend_Counter::~Suspend_Counter()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();
	delete onSuspendAction();
	delete onResumeAction();

	delete _transitions[0];
}

void Suspend_Counter::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Suspend_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Suspend_Counter_FuncRefs.mm"
#	include "State_Suspend_Counter_OnEntry.mm"
}

void Suspend_Counter::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Suspend_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Suspend_Counter_FuncRefs.mm"
#	include "State_Suspend_Counter_OnExit.mm"
}

void Suspend_Counter::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Suspend_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Suspend_Counter_FuncRefs.mm"
#	include "State_Suspend_Counter_Internal.mm"
}

void Suspend_Counter::OnSuspend::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Suspend_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Suspend_Counter_FuncRefs.mm"
#	include "State_Suspend_Counter_OnSuspend.mm"
}

void Suspend_Counter::OnResume::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Suspend_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Suspend_Counter_FuncRefs.mm"
#	include "State_Suspend_Counter_OnResume.mm"
}

bool Suspend_Counter::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Suspend_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Suspend_Counter_FuncRefs.mm"

	return
	(
#		include "State_Suspend_Counter_Transition_0.expr"
	);
}
