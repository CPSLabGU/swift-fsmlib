//
// State_Print.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Counter_Includes.h"
#include "Counter.h"
#include "State_Print.h"

#include "State_Print_Includes.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

using namespace FSM;
using namespace CLM;
using namespace FSMCounter;
using namespace State;

Print::Print(const char *name): CLState(name, *new Print::OnEntry, *new Print::OnExit, *new Print::Internal, NULLPTR, new Print::OnSuspend, new Print::OnResume)
{
	_transitions[0] = new Transition_0();
}

Print::~Print()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();
	delete onSuspendAction();
	delete onResumeAction();

	delete _transitions[0];
}

void Print::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_Print_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_Print_FuncRefs.mm"
#	include "State_Print_OnEntry.mm"
}

void Print::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_Print_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_Print_FuncRefs.mm"
#	include "State_Print_OnExit.mm"
}

void Print::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_Print_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_Print_FuncRefs.mm"
#	include "State_Print_Internal.mm"
}

void Print::OnSuspend::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_Print_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_Print_FuncRefs.mm"
#	include "State_Print_OnSuspend.mm"
}

void Print::OnResume::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_Print_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_Print_FuncRefs.mm"
#	include "State_Print_OnResume.mm"
}

bool Print::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_Print_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_Print_FuncRefs.mm"

	return
	(
#		include "State_Print_Transition_0.expr"
	);
}
