
################################################################################
# MIPS Assembly generated from LLFSM arrangement FischerDelaysByBooleanSensors
################################################################################

.data


# Global Integer Constants

.eqv CNT_NotAThread, 0



# State encoding

.eqv STARTER_DINIT, 0
.eqv STARTER_START, 1


.eqv THREAD_1_DINIT, 0
.eqv THREAD_1_T1NonCriticalSection, 1

.eqv THREAD_1_T1Wait, 2

.eqv THREAD_1_T1Assign, 3

.eqv THREAD_1_T1CriticalSection, 4

.eqv THREAD_1_T1LetGo, 5


.eqv THREAD_2_DINIT, 0
.eqv THREAD_2_T2NonCriticalSection, 1

.eqv THREAD_2_T2Wait, 2

.eqv THREAD_2_T2Assign, 3

.eqv THREAD_2_T2CriticalSection, 4

.eqv THREAD_2_T2LetGo, 5



.eqv MAX_STEPS, 20
.eqv NUM_MACHINES, 3

# String constants
arr_name:       .asciiz "LLFSM Arrangement: FischerDelaysByBooleanSensors\n"
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


# State name strings for STARTER
sm_STARTER_name: .asciiz "STARTER"
sn_STARTER_dinit: .asciiz "dInitSTARTER"
sn_STARTER_START: .asciiz "START"

# OnEntry strings for STARTER



oe_STARTER_START_0: .asciiz "Initialise shared variable\n"







# State name strings for THREAD_1
sm_THREAD_1_name: .asciiz "THREAD_1"
sn_THREAD_1_dinit: .asciiz "dInitTHREAD_1"
sn_THREAD_1_T1NonCriticalSection: .asciiz "T1NonCriticalSection"

sn_THREAD_1_T1Wait: .asciiz "T1Wait"

sn_THREAD_1_T1Assign: .asciiz "T1Assign"

sn_THREAD_1_T1CriticalSection: .asciiz "T1CriticalSection"

sn_THREAD_1_T1LetGo: .asciiz "T1LetGo"

# OnEntry strings for THREAD_1



oe_THREAD_1_T1NonCriticalSection_0: .asciiz "T1 in non-critical section\n"























# State name strings for THREAD_2
sm_THREAD_2_name: .asciiz "THREAD_2"
sn_THREAD_2_dinit: .asciiz "dInitTHREAD_2"
sn_THREAD_2_T2NonCriticalSection: .asciiz "T2NonCriticalSection"

sn_THREAD_2_T2Wait: .asciiz "T2Wait"

sn_THREAD_2_T2Assign: .asciiz "T2Assign"

sn_THREAD_2_T2CriticalSection: .asciiz "T2CriticalSection"

sn_THREAD_2_T2LetGo: .asciiz "T2LetGo"

# OnEntry strings for THREAD_2



oe_THREAD_2_T2NonCriticalSection_0: .asciiz "T2 in non-critical section\n"
























# Variables


var_SharedX:    .word 0




var_T1NonCriticalSectionDelay:    .word 0

var_T1CriticalSectionDelay:    .word 0

var_T2NonCriticalSectionDelay:    .word 0

var_T2CriticalSectionDelay:    .word 0




pc_STARTER:  .word 0



pc_THREAD_1:  .word 0


var_THREAD_1_IamThreadT1:    .word 0




pc_THREAD_2:  .word 0


var_THREAD_2_IamThreadT2:    .word 0





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

onEntry_STARTER_START:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_STARTER_START_0
    jal print_str




    li $t0, CNT_NotAThread
    sw $t0, var_SharedX




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra



onEntry_THREAD_1_T1NonCriticalSection:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_THREAD_1_T1NonCriticalSection_0
    jal print_str




    li $t0, 1
    sw $t0, var_IamThreadT1




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_THREAD_1_T1Wait:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_THREAD_1_T1Assign:
    addi $sp, $sp, -4
    sw $ra, 0($sp)




    lw $t0, var_IamThreadT1
    sw $t0, var_SharedX




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_THREAD_1_T1CriticalSection:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_THREAD_1_T1LetGo:
    addi $sp, $sp, -4
    sw $ra, 0($sp)




    li $t0, CNT_NotAThread
    sw $t0, var_SharedX




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra



onEntry_THREAD_2_T2NonCriticalSection:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_THREAD_2_T2NonCriticalSection_0
    jal print_str




    li $t0, 2
    sw $t0, var_IamThreadT2




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_THREAD_2_T2Wait:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_THREAD_2_T2Assign:
    addi $sp, $sp, -4
    sw $ra, 0($sp)




    lw $t0, var_IamThreadT2
    sw $t0, var_SharedX




    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_THREAD_2_T2CriticalSection:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_THREAD_2_T2LetGo:
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

step_STARTER:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    lw $t1, pc_STARTER
    # Check pseudo-initial
    bne $t1, STARTER_DINIT, step_STARTER_check_trans
    li $t0, STARTER_START
    sw $t0, pc_STARTER
    jal onEntry_STARTER_START
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_STARTER_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_STARTER_dinit
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_STARTER_START
    jal print_str
    la $a0, newline
    jal print_str
    j step_STARTER_done

step_STARTER_check_trans:

    # No transition taken

step_STARTER_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


step_THREAD_1:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    lw $t1, pc_THREAD_1
    # Check pseudo-initial
    bne $t1, THREAD_1_DINIT, step_THREAD_1_check_trans
    li $t0, THREAD_1_T1NonCriticalSection
    sw $t0, pc_THREAD_1
    jal onEntry_THREAD_1_T1NonCriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_1_dinit
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_1_T1NonCriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_1_done

step_THREAD_1_check_trans:


    # Transition 0: T1NonCriticalSection -> T1Wait
    lw $t1, pc_THREAD_1
    bne $t1, THREAD_1_T1NonCriticalSection, skip_THREAD_1_tr0
    # Evaluate guard
    lw $t2, var_T1NonCriticalSectionDelay
    beq $t2, $zero, skip_THREAD_1_tr0
    # Take transition
    li $t0, THREAD_1_T1Wait
    sw $t0, pc_THREAD_1
    jal onEntry_THREAD_1_T1Wait
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_1_T1NonCriticalSection
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_1_T1Wait
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_1_done
skip_THREAD_1_tr0:



    # Transition 1: T1Wait -> T1Assign
    lw $t1, pc_THREAD_1
    bne $t1, THREAD_1_T1Wait, skip_THREAD_1_tr1
    # Evaluate guard
    li $t3, CNT_NotAThread
    lw $t4, var_SharedX
    seq $t2, $t3, $t4
    beq $t2, $zero, skip_THREAD_1_tr1
    # Take transition
    li $t0, THREAD_1_T1Assign
    sw $t0, pc_THREAD_1
    jal onEntry_THREAD_1_T1Assign
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_1_T1Wait
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_1_T1Assign
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_1_done
skip_THREAD_1_tr1:



    # Transition 2: T1Assign -> T1Wait
    lw $t1, pc_THREAD_1
    bne $t1, THREAD_1_T1Assign, skip_THREAD_1_tr2
    # Evaluate guard
    lw $t3, var_IamThreadT1
    lw $t4, var_SharedX
    sne $t2, $t3, $t4
    beq $t2, $zero, skip_THREAD_1_tr2
    # Take transition
    li $t0, THREAD_1_T1Wait
    sw $t0, pc_THREAD_1
    jal onEntry_THREAD_1_T1Wait
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_1_T1Assign
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_1_T1Wait
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_1_done
skip_THREAD_1_tr2:



    # Transition 3: T1Assign -> T1CriticalSection
    lw $t1, pc_THREAD_1
    bne $t1, THREAD_1_T1Assign, skip_THREAD_1_tr3
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_THREAD_1_tr3
    # Take transition
    li $t0, THREAD_1_T1CriticalSection
    sw $t0, pc_THREAD_1
    jal onEntry_THREAD_1_T1CriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_1_T1Assign
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_1_T1CriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_1_done
skip_THREAD_1_tr3:



    # Transition 4: T1CriticalSection -> T1LetGo
    lw $t1, pc_THREAD_1
    bne $t1, THREAD_1_T1CriticalSection, skip_THREAD_1_tr4
    # Evaluate guard
    lw $t2, var_T1CriticalSectionDelay
    beq $t2, $zero, skip_THREAD_1_tr4
    # Take transition
    li $t0, THREAD_1_T1LetGo
    sw $t0, pc_THREAD_1
    jal onEntry_THREAD_1_T1LetGo
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_1_T1CriticalSection
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_1_T1LetGo
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_1_done
skip_THREAD_1_tr4:



    # Transition 5: T1LetGo -> T1NonCriticalSection
    lw $t1, pc_THREAD_1
    bne $t1, THREAD_1_T1LetGo, skip_THREAD_1_tr5
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_THREAD_1_tr5
    # Take transition
    li $t0, THREAD_1_T1NonCriticalSection
    sw $t0, pc_THREAD_1
    jal onEntry_THREAD_1_T1NonCriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_1_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_1_T1LetGo
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_1_T1NonCriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_1_done
skip_THREAD_1_tr5:


    # No transition taken

step_THREAD_1_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


step_THREAD_2:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    lw $t1, pc_THREAD_2
    # Check pseudo-initial
    bne $t1, THREAD_2_DINIT, step_THREAD_2_check_trans
    li $t0, THREAD_2_T2NonCriticalSection
    sw $t0, pc_THREAD_2
    jal onEntry_THREAD_2_T2NonCriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_2_dinit
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_2_T2NonCriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_2_done

step_THREAD_2_check_trans:


    # Transition 0: T2NonCriticalSection -> T2Wait
    lw $t1, pc_THREAD_2
    bne $t1, THREAD_2_T2NonCriticalSection, skip_THREAD_2_tr0
    # Evaluate guard
    lw $t2, var_T2NonCriticalSectionDelay
    beq $t2, $zero, skip_THREAD_2_tr0
    # Take transition
    li $t0, THREAD_2_T2Wait
    sw $t0, pc_THREAD_2
    jal onEntry_THREAD_2_T2Wait
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_2_T2NonCriticalSection
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_2_T2Wait
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_2_done
skip_THREAD_2_tr0:



    # Transition 1: T2Wait -> T2Assign
    lw $t1, pc_THREAD_2
    bne $t1, THREAD_2_T2Wait, skip_THREAD_2_tr1
    # Evaluate guard
    li $t3, CNT_NotAThread
    lw $t4, var_SharedX
    seq $t2, $t3, $t4
    beq $t2, $zero, skip_THREAD_2_tr1
    # Take transition
    li $t0, THREAD_2_T2Assign
    sw $t0, pc_THREAD_2
    jal onEntry_THREAD_2_T2Assign
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_2_T2Wait
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_2_T2Assign
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_2_done
skip_THREAD_2_tr1:



    # Transition 2: T2Assign -> T2Wait
    lw $t1, pc_THREAD_2
    bne $t1, THREAD_2_T2Assign, skip_THREAD_2_tr2
    # Evaluate guard
    lw $t3, var_IamThreadT2
    lw $t4, var_SharedX
    sne $t2, $t3, $t4
    beq $t2, $zero, skip_THREAD_2_tr2
    # Take transition
    li $t0, THREAD_2_T2Wait
    sw $t0, pc_THREAD_2
    jal onEntry_THREAD_2_T2Wait
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_2_T2Assign
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_2_T2Wait
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_2_done
skip_THREAD_2_tr2:



    # Transition 3: T2Assign -> T2CriticalSection
    lw $t1, pc_THREAD_2
    bne $t1, THREAD_2_T2Assign, skip_THREAD_2_tr3
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_THREAD_2_tr3
    # Take transition
    li $t0, THREAD_2_T2CriticalSection
    sw $t0, pc_THREAD_2
    jal onEntry_THREAD_2_T2CriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_2_T2Assign
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_2_T2CriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_2_done
skip_THREAD_2_tr3:



    # Transition 4: T2CriticalSection -> T2LetGo
    lw $t1, pc_THREAD_2
    bne $t1, THREAD_2_T2CriticalSection, skip_THREAD_2_tr4
    # Evaluate guard
    lw $t2, var_T2CriticalSectionDelay
    beq $t2, $zero, skip_THREAD_2_tr4
    # Take transition
    li $t0, THREAD_2_T2LetGo
    sw $t0, pc_THREAD_2
    jal onEntry_THREAD_2_T2LetGo
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_2_T2CriticalSection
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_2_T2LetGo
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_2_done
skip_THREAD_2_tr4:



    # Transition 5: T2LetGo -> T2NonCriticalSection
    lw $t1, pc_THREAD_2
    bne $t1, THREAD_2_T2LetGo, skip_THREAD_2_tr5
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_THREAD_2_tr5
    # Take transition
    li $t0, THREAD_2_T2NonCriticalSection
    sw $t0, pc_THREAD_2
    jal onEntry_THREAD_2_T2NonCriticalSection
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_THREAD_2_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_THREAD_2_T2LetGo
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_THREAD_2_T2NonCriticalSection
    jal print_str
    la $a0, newline
    jal print_str
    j step_THREAD_2_done
skip_THREAD_2_tr5:


    # No transition taken

step_THREAD_2_done:
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
    jal step_STARTER
    j sched_next
sched_skip_0:



    li $t0, 1
    bne $s1, $t0, sched_skip_1
    jal step_THREAD_1
    j sched_next
sched_skip_1:



    li $t0, 2
    bne $s1, $t0, sched_skip_2
    jal step_THREAD_2
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
