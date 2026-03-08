
################################################################################
# MIPS Assembly generated from LLFSM arrangement PingPongTikiTakaForC
################################################################################

.data



# State encoding

.eqv PingPong_DINIT, 0
.eqv PingPong_START_PING_PONG, 1

.eqv PingPong_PING, 2

.eqv PingPong_PONG, 3



.eqv MAX_STEPS, 20
.eqv NUM_MACHINES, 1

# String constants
arr_name:       .asciiz "LLFSM Arrangement: PingPongTikiTakaForC\n"
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


# State name strings for PingPong
sm_PingPong_name: .asciiz "PingPong"
sn_PingPong_dinit: .asciiz "dInitPingPong"
sn_PingPong_START_PING_PONG: .asciiz "START_PING_PONG"

sn_PingPong_PING: .asciiz "PING"

sn_PingPong_PONG: .asciiz "PONG"

# OnEntry strings for PingPong



oe_PingPong_START_PING_PONG_0: .asciiz "Start Ping Pong\n"







oe_PingPong_PING_0: .asciiz "ping\n"







oe_PingPong_PONG_0: .asciiz "pong\n"






# Variables




pc_PingPong:  .word 0




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

onEntry_PingPong_START_PING_PONG:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_PingPong_START_PING_PONG_0
    jal print_str



    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_PingPong_PING:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_PingPong_PING_0
    jal print_str



    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


onEntry_PingPong_PONG:
    addi $sp, $sp, -4
    sw $ra, 0($sp)



    la $a0, oe_PingPong_PONG_0
    jal print_str



    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra




################################################################################
# Step functions
################################################################################

step_PingPong:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    lw $t1, pc_PingPong
    # Check pseudo-initial
    bne $t1, PingPong_DINIT, step_PingPong_check_trans
    li $t0, PingPong_START_PING_PONG
    sw $t0, pc_PingPong
    jal onEntry_PingPong_START_PING_PONG
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_PingPong_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_PingPong_dinit
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_PingPong_START_PING_PONG
    jal print_str
    la $a0, newline
    jal print_str
    j step_PingPong_done

step_PingPong_check_trans:


    # Transition 0: START_PING_PONG -> PING
    lw $t1, pc_PingPong
    bne $t1, PingPong_START_PING_PONG, skip_PingPong_tr0
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_PingPong_tr0
    # Take transition
    li $t0, PingPong_PING
    sw $t0, pc_PingPong
    jal onEntry_PingPong_PING
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_PingPong_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_PingPong_START_PING_PONG
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_PingPong_PING
    jal print_str
    la $a0, newline
    jal print_str
    j step_PingPong_done
skip_PingPong_tr0:



    # Transition 1: PING -> PONG
    lw $t1, pc_PingPong
    bne $t1, PingPong_PING, skip_PingPong_tr1
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_PingPong_tr1
    # Take transition
    li $t0, PingPong_PONG
    sw $t0, pc_PingPong
    jal onEntry_PingPong_PONG
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_PingPong_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_PingPong_PING
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_PingPong_PONG
    jal print_str
    la $a0, newline
    jal print_str
    j step_PingPong_done
skip_PingPong_tr1:



    # Transition 2: PONG -> PING
    lw $t1, pc_PingPong
    bne $t1, PingPong_PONG, skip_PingPong_tr2
    # Evaluate guard
    li $t2, 1
    beq $t2, $zero, skip_PingPong_tr2
    # Take transition
    li $t0, PingPong_PING
    sw $t0, pc_PingPong
    jal onEntry_PingPong_PING
    # Print transition
    la $a0, dinit_prefix
    jal print_str
    la $a0, sm_PingPong_name
    jal print_str
    la $a0, bracket_space
    jal print_str
    la $a0, sn_PingPong_PONG
    jal print_str
    la $a0, arrow
    jal print_str
    la $a0, sn_PingPong_PING
    jal print_str
    la $a0, newline
    jal print_str
    j step_PingPong_done
skip_PingPong_tr2:


    # No transition taken

step_PingPong_done:
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
    jal step_PingPong
    j sched_next
sched_skip_0:



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
