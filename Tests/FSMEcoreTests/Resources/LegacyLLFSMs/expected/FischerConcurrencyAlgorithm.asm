
################################################################################
# MIPS Assembly generated from LLFSM arrangement FischerConcurrencyAlgorithm
################################################################################

.data


# Global Integer Constants

.eqv CNT_NotAThread, 0

.eqv CNT_GlobalWCET, 0



# State encoding

.eqv Starter_DINIT, 0
.eqv Starter_INITIAL, 1


.eqv Thread1_DINIT, 0
.eqv Thread1_T1NonCriticalSection, 1

.eqv Thread1_T1WAIT, 2

.eqv Thread1_T1ASSIGN, 3

.eqv Thread1_T1CriticalSection, 4

.eqv Thread1_T1LetGo, 5


.eqv Thread2_DINIT, 0
.eqv Thread2_T2NonCriticalSection, 1

.eqv Thread2_T2WAIT, 2

.eqv Thread2_T2ASSIGN, 3

.eqv Thread2_T2CriticalSection, 4

.eqv Thread2_T2LetGo, 5



.eqv MAX_STEPS, 20
.eqv NUM_MACHINES, 3

# String constants
arr_name:       .asciiz "LLFSM Arrangement: FischerConcurrencyAlgorithm\n"
running_msg:    .asciiz "Running 20 scheduler steps\n\n"
step_prefix:    .asciiz "Step "
turn_prefix:    .asciiz " (turn="
turn_suffix:    .asciiz "):\n"
arrow:          .asciiz " -> "
newline:        .asciiz "\n"
complete_msg:   .asciiz "\nSimulation complete.\n"
dinit_prefix:   .asciiz "  ["
dinit_mid:      .asciiz "] dInit"
bracket_space:  .asciiz "] "


# State name strings for Starter
sm_Starter_name: .asciiz "Starter"
sn_Starter_dinit: .asciiz "dInitStarter"
sn_Starter_INITIAL: .asciiz "INITIAL"

# OnEntry strings for Starter



oe_Starter_INITIAL_0: .asciiz "Initialise shared varianle\n"







# State name strings for Thread1
sm_Thread1_name: .asciiz "Thread1"
sn_Thread1_dinit: .asciiz "dInitThread1"
sn_Thread1_T1NonCriticalSection: .asciiz "T1NonCriticalSection"

sn_Thread1_T1WAIT: .asciiz "T1WAIT"

sn_Thread1_T1ASSIGN: .asciiz "T1ASSIGN"

sn_Thread1_T1CriticalSection: .asciiz "T1CriticalSection"

sn_Thread1_T1LetGo: .asciiz "T1LetGo"

# OnEntry strings for Thread1



oe_Thread1_T1NonCriticalSection_0: .asciiz "In T1 non critical section\n"

















oe_Thread1_T1CriticalSection_0: .asciiz "In T1 critical section\n"











# State name strings for Thread2
sm_Thread2_name: .asciiz "Thread2"
sn_Thread2_dinit: .asciiz "dInitThread2"
sn_Thread2_T2NonCriticalSection: .asciiz "T2NonCriticalSection"

sn_Thread2_T2WAIT: .asciiz "T2WAIT"

sn_Thread2_T2ASSIGN: .asciiz "T2ASSIGN"

sn_Thread2_T2CriticalSection: .asciiz "T2CriticalSection"

sn_Thread2_T2LetGo: .asciiz "T2LetGo"

# OnEntry strings for Thread2



oe_Thread2_T2NonCriticalSection_0: .asciiz "In T2 non critical section\n"

















oe_Thread2_T2CriticalSection_0: .asciiz "In T2 critical section\n"












# Variables


var_SharedX:    .word 0





pc_Starter:  .word 0



pc_Thread1:  .word 0


var_Thread1_IamThreadT1:    .word 0




pc_Thread2:  .word 0


var_Thread2_IamThreadT2:    .word 0





################################################################################
.text
.globl main

# Print string macro: la $a0, label; jal print_str
print_str:
    li $v0, 4
    syscall
    jr $ra

# Print integer macro: move $a0, value; jal print_int
print_int:
    li $v0, 1
    syscall
    jr $ra

################################################################################
# OnEntry action functions
################################################################################

onEntry_Starter_INITIAL:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_Starter_INITIAL_0
    jal print_str




    li $t0, CNT_NotAThread
    sw $t0, var_SharedX




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra



onEntry_Thread1_T1NonCriticalSection:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_Thread1_T1NonCriticalSection_0
    jal print_str




    li $t0, 1
    sw $t0, var_IamThreadT1




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_Thread1_T1WAIT:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_Thread1_T1ASSIGN:
    addi $sp, $sp, -4
    sw $ra, 0($sp)




    lw $t0, var_IamThreadT1
    sw $t0, var_SharedX




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_Thread1_T1CriticalSection:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_Thread1_T1CriticalSection_0
    jal print_str



    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_Thread1_T1LetGo:
    addi $sp, $sp, -4
    sw $ra, 0($sp)




    li $t0, CNT_NotAThread
    sw $t0, var_SharedX




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra



onEntry_Thread2_T2NonCriticalSection:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_Thread2_T2NonCriticalSection_0
    jal print_str




    li $t0, 2
    sw $t0, var_IamThreadT2




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_Thread2_T2WAIT:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_Thread2_T2ASSIGN:
    addi $sp, $sp, -4
    sw $ra, 0($sp)




    lw $t0, var_IamThreadT2
    sw $t0, var_SharedX




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_Thread2_T2CriticalSection:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_Thread2_T2CriticalSection_0
    jal print_str



    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_Thread2_T2LetGo:
    addi $sp, $sp, -4
    sw $ra, 0($sp)




    li $t0, CNT_NotAThread
    sw $t0, var_SharedX




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra




################################################################################
# Step functions
################################################################################

step_Starter:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    lw $t1, pc_Starter
    # Check pseudo-initial
    bne $t1, Starter_DINIT, step_Starter_check_trans
    li $t0, Starter_INITIAL
    sw $t0, pc_Starter
    jal onEntry_Starter_INITIAL
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Starter_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Starter_dinit
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Starter_INITIAL
    jal print_str
    la $a0, newline
    jal print_str
    j step_Starter_done

step_Starter_check_trans:

    # No transition taken

step_Starter_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


step_Thread1:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    lw $t1, pc_Thread1
    # Check pseudo-initial
    bne $t1, Thread1_DINIT, step_Thread1_check_trans
    li $t0, Thread1_T1NonCriticalSection
    sw $t0, pc_Thread1
    jal onEntry_Thread1_T1NonCriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread1_dinit
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread1_T1NonCriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread1_done

step_Thread1_check_trans:


    # Transition 0: T1NonCriticalSection -> T1WAIT
    lw $t1, pc_Thread1
    bne $t1, Thread1_T1NonCriticalSection, skip_Thread1_tr0
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_Thread1_tr0
    # Take transition
    li $t0, Thread1_T1WAIT
    sw $t0, pc_Thread1
    jal onEntry_Thread1_T1WAIT
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread1_T1NonCriticalSection
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread1_T1WAIT
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread1_done
skip_Thread1_tr0:



    # Transition 1: T1WAIT -> T1ASSIGN
    lw $t1, pc_Thread1
    bne $t1, Thread1_T1WAIT, skip_Thread1_tr1
    # Evaluate guard
    li $t3, CNT_NotAThread
    lw $t4, var_SharedX
    seq $t2, $t3, $t4
    beq $t2, $zero, skip_Thread1_tr1
    # Take transition
    li $t0, Thread1_T1ASSIGN
    sw $t0, pc_Thread1
    jal onEntry_Thread1_T1ASSIGN
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread1_T1WAIT
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread1_T1ASSIGN
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread1_done
skip_Thread1_tr1:



    # Transition 2: T1ASSIGN -> T1WAIT
    lw $t1, pc_Thread1
    bne $t1, Thread1_T1ASSIGN, skip_Thread1_tr2
    # Evaluate guard
    lw $t3, var_IamThreadT1
    lw $t4, var_SharedX
    sne $t2, $t3, $t4
    beq $t2, $zero, skip_Thread1_tr2
    # Take transition
    li $t0, Thread1_T1WAIT
    sw $t0, pc_Thread1
    jal onEntry_Thread1_T1WAIT
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread1_T1ASSIGN
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread1_T1WAIT
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread1_done
skip_Thread1_tr2:



    # Transition 3: T1ASSIGN -> T1CriticalSection
    lw $t1, pc_Thread1
    bne $t1, Thread1_T1ASSIGN, skip_Thread1_tr3
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_Thread1_tr3
    # Take transition
    li $t0, Thread1_T1CriticalSection
    sw $t0, pc_Thread1
    jal onEntry_Thread1_T1CriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread1_T1ASSIGN
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread1_T1CriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread1_done
skip_Thread1_tr3:



    # Transition 4: T1CriticalSection -> T1LetGo
    lw $t1, pc_Thread1
    bne $t1, Thread1_T1CriticalSection, skip_Thread1_tr4
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_Thread1_tr4
    # Take transition
    li $t0, Thread1_T1LetGo
    sw $t0, pc_Thread1
    jal onEntry_Thread1_T1LetGo
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread1_T1CriticalSection
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread1_T1LetGo
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread1_done
skip_Thread1_tr4:



    # Transition 5: T1LetGo -> T1NonCriticalSection
    lw $t1, pc_Thread1
    bne $t1, Thread1_T1LetGo, skip_Thread1_tr5
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_Thread1_tr5
    # Take transition
    li $t0, Thread1_T1NonCriticalSection
    sw $t0, pc_Thread1
    jal onEntry_Thread1_T1NonCriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread1_T1LetGo
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread1_T1NonCriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread1_done
skip_Thread1_tr5:


    # No transition taken

step_Thread1_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


step_Thread2:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    lw $t1, pc_Thread2
    # Check pseudo-initial
    bne $t1, Thread2_DINIT, step_Thread2_check_trans
    li $t0, Thread2_T2NonCriticalSection
    sw $t0, pc_Thread2
    jal onEntry_Thread2_T2NonCriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread2_dinit
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread2_T2NonCriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread2_done

step_Thread2_check_trans:


    # Transition 0: T2NonCriticalSection -> T2WAIT
    lw $t1, pc_Thread2
    bne $t1, Thread2_T2NonCriticalSection, skip_Thread2_tr0
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_Thread2_tr0
    # Take transition
    li $t0, Thread2_T2WAIT
    sw $t0, pc_Thread2
    jal onEntry_Thread2_T2WAIT
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread2_T2NonCriticalSection
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread2_T2WAIT
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread2_done
skip_Thread2_tr0:



    # Transition 1: T2WAIT -> T2ASSIGN
    lw $t1, pc_Thread2
    bne $t1, Thread2_T2WAIT, skip_Thread2_tr1
    # Evaluate guard
    li $t3, CNT_NotAThread
    lw $t4, var_SharedX
    seq $t2, $t3, $t4
    beq $t2, $zero, skip_Thread2_tr1
    # Take transition
    li $t0, Thread2_T2ASSIGN
    sw $t0, pc_Thread2
    jal onEntry_Thread2_T2ASSIGN
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread2_T2WAIT
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread2_T2ASSIGN
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread2_done
skip_Thread2_tr1:



    # Transition 2: T2ASSIGN -> T2WAIT
    lw $t1, pc_Thread2
    bne $t1, Thread2_T2ASSIGN, skip_Thread2_tr2
    # Evaluate guard
    lw $t3, var_IamThreadT2
    lw $t4, var_SharedX
    sne $t2, $t3, $t4
    beq $t2, $zero, skip_Thread2_tr2
    # Take transition
    li $t0, Thread2_T2WAIT
    sw $t0, pc_Thread2
    jal onEntry_Thread2_T2WAIT
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread2_T2ASSIGN
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread2_T2WAIT
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread2_done
skip_Thread2_tr2:



    # Transition 3: T2ASSIGN -> T2CriticalSection
    lw $t1, pc_Thread2
    bne $t1, Thread2_T2ASSIGN, skip_Thread2_tr3
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_Thread2_tr3
    # Take transition
    li $t0, Thread2_T2CriticalSection
    sw $t0, pc_Thread2
    jal onEntry_Thread2_T2CriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread2_T2ASSIGN
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread2_T2CriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread2_done
skip_Thread2_tr3:



    # Transition 4: T2CriticalSection -> T2LetGo
    lw $t1, pc_Thread2
    bne $t1, Thread2_T2CriticalSection, skip_Thread2_tr4
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_Thread2_tr4
    # Take transition
    li $t0, Thread2_T2LetGo
    sw $t0, pc_Thread2
    jal onEntry_Thread2_T2LetGo
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread2_T2CriticalSection
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread2_T2LetGo
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread2_done
skip_Thread2_tr4:



    # Transition 5: T2LetGo -> T2NonCriticalSection
    lw $t1, pc_Thread2
    bne $t1, Thread2_T2LetGo, skip_Thread2_tr5
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_Thread2_tr5
    # Take transition
    li $t0, Thread2_T2NonCriticalSection
    sw $t0, pc_Thread2
    jal onEntry_Thread2_T2NonCriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_Thread2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_Thread2_T2LetGo
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_Thread2_T2NonCriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_Thread2_done
skip_Thread2_tr5:


    # No transition taken

step_Thread2_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra



################################################################################
# Main entry point
################################################################################
main:
    # Print header
    la $a0, arr_name
    jal print_str
    la $a0, running_msg
    jal print_str

    li $s0, 0           # i = step counter
    li $s1, 0           # turn
    li $s2, MAX_STEPS   # max steps

scheduler_loop:
    bge $s0, $s2, scheduler_done

    # Print "Step X (turn=Y):\n"
    la $a0, step_prefix
    jal print_str
    move $a0, $s0
    jal print_int
    la $a0, turn_prefix
    jal print_str
    move $a0, $s1
    jal print_int
    la $a0, turn_suffix
    jal print_str

    # Dispatch based on turn


    li $t0, 0
    bne $s1, $t0, sched_skip_0
    jal step_Starter
    j sched_next
sched_skip_0:



    li $t0, 1
    bne $s1, $t0, sched_skip_1
    jal step_Thread1
    j sched_next
sched_skip_1:



    li $t0, 2
    bne $s1, $t0, sched_skip_2
    jal step_Thread2
    j sched_next
sched_skip_2:



sched_next:
    addi $s0, $s0, 1
    addi $s1, $s1, 1
    li $t0, NUM_MACHINES
    rem $s1, $s1, $t0
    j scheduler_loop

scheduler_done:
    la $a0, complete_msg
    jal print_str
    li $v0, 10
    syscall
