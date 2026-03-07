//
// State_State_2.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "Machine2_Includes.h"
#include "Machine2.h"
#include "State_State_2.h"

#include "State_State_2_Includes.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat"

using namespace FSM;
using namespace CLM;
using namespace FSMMachine2;
using namespace State;

State_2::State_2(const char *name): CLState(name, *new State_2::OnEntry, *new State_2::OnExit, *new State_2::Internal, NULLPTR, new State_2::OnSuspend, new State_2::OnResume)
{
}

State_2::~State_2()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();
	delete onSuspendAction();
	delete onResumeAction();

}

void State_2::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine2_VarRefs.mm"
#	include "State_State_2_VarRefs.mm"
#	include "Machine2_FuncRefs.mm"
#	include "State_State_2_FuncRefs.mm"
#	include "State_State_2_OnEntry.mm"
}

void State_2::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine2_VarRefs.mm"
#	include "State_State_2_VarRefs.mm"
#	include "Machine2_FuncRefs.mm"
#	include "State_State_2_FuncRefs.mm"
#	include "State_State_2_OnExit.mm"
}

void State_2::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine2_VarRefs.mm"
#	include "State_State_2_VarRefs.mm"
#	include "Machine2_FuncRefs.mm"
#	include "State_State_2_FuncRefs.mm"
#	include "State_State_2_Internal.mm"
}

void State_2::OnSuspend::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine2_VarRefs.mm"
#	include "State_State_2_VarRefs.mm"
#	include "Machine2_FuncRefs.mm"
#	include "State_State_2_FuncRefs.mm"
#	include "State_State_2_OnSuspend.mm"
}

void State_2::OnResume::perform(CLMachine *_machine, CLState *_state) const
{
#	include "Machine2_VarRefs.mm"
#	include "State_State_2_VarRefs.mm"
#	include "Machine2_FuncRefs.mm"
#	include "State_State_2_FuncRefs.mm"
#	include "State_State_2_OnResume.mm"
}
