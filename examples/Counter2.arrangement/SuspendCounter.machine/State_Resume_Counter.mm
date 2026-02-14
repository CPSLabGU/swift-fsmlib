//
// State_Resume_Counter.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "SuspendCounter_Includes.h"
#include "SuspendCounter.h"
#include "State_Resume_Counter.h"

#include "State_Resume_Counter_Includes.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

using namespace FSM;
using namespace CLM;
using namespace FSMSuspendCounter;
using namespace State;

Resume_Counter::Resume_Counter(const char *name): CLState(name, *new Resume_Counter::OnEntry, *new Resume_Counter::OnExit, *new Resume_Counter::Internal, NULLPTR, new Resume_Counter::OnSuspend, new Resume_Counter::OnResume)
{
}

Resume_Counter::~Resume_Counter()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();
	delete onSuspendAction();
	delete onResumeAction();

}

void Resume_Counter::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Resume_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Resume_Counter_FuncRefs.mm"
#	include "State_Resume_Counter_OnEntry.mm"
}

void Resume_Counter::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Resume_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Resume_Counter_FuncRefs.mm"
#	include "State_Resume_Counter_OnExit.mm"
}

void Resume_Counter::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Resume_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Resume_Counter_FuncRefs.mm"
#	include "State_Resume_Counter_Internal.mm"
}

void Resume_Counter::OnSuspend::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Resume_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Resume_Counter_FuncRefs.mm"
#	include "State_Resume_Counter_OnSuspend.mm"
}

void Resume_Counter::OnResume::perform(CLMachine *_machine, CLState *_state) const
{
#	include "SuspendCounter_VarRefs.mm"
#	include "State_Resume_Counter_VarRefs.mm"
#	include "SuspendCounter_FuncRefs.mm"
#	include "State_Resume_Counter_FuncRefs.mm"
#	include "State_Resume_Counter_OnResume.mm"
}
