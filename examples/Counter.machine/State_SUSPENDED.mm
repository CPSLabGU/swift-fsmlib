//
// State_SUSPENDED.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Counter_Includes.h"
#include "Counter.h"
#include "State_SUSPENDED.h"

#include "State_SUSPENDED_Includes.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

using namespace FSM;
using namespace CLM;
using namespace FSMCounter;
using namespace State;

SUSPENDED::SUSPENDED(const char *name): CLState(name, *new SUSPENDED::OnEntry, *new SUSPENDED::OnExit, *new SUSPENDED::Internal, NULLPTR, new SUSPENDED::OnSuspend, new SUSPENDED::OnResume)
{
}

SUSPENDED::~SUSPENDED()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();
	delete onSuspendAction();
	delete onResumeAction();

}

void SUSPENDED::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_SUSPENDED_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_SUSPENDED_FuncRefs.mm"
#	include "State_SUSPENDED_OnEntry.mm"
}

void SUSPENDED::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_SUSPENDED_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_SUSPENDED_FuncRefs.mm"
#	include "State_SUSPENDED_OnExit.mm"
}

void SUSPENDED::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_SUSPENDED_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_SUSPENDED_FuncRefs.mm"
#	include "State_SUSPENDED_Internal.mm"
}

void SUSPENDED::OnSuspend::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_SUSPENDED_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_SUSPENDED_FuncRefs.mm"
#	include "State_SUSPENDED_OnSuspend.mm"
}

void SUSPENDED::OnResume::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Counter_VarRefs.mm"
#	include "State_SUSPENDED_VarRefs.mm"
#	include "Counter_FuncRefs.mm"
#	include "State_SUSPENDED_FuncRefs.mm"
#	include "State_SUSPENDED_OnResume.mm"
}
