

############################################################
#  TASK 4 – Entertain (E n) & Pet (P n) Commands
#  Author: Lele Li (COMP0068 Digital Pet Project 2025/26)
#
#  Function:
#     Handle user commands that increase a pet’s energy by 2 × n
#     and cap the value at the maximum energy level (MEL).
#
#  Specification:
#     • Two pets are supported: Pet A and Pet B.
#     • Entertain (E n) and Pet (P n) share the same logic.
#
#  Register usage:
#     $s0 = current_energy_petA
#     $s1 = current_energy_petB
#     $s2 = MEL  (maximum energy level)
#     $a0 = pet ID (1 = A, 2 = B)
#     $a1 = n   (value entered by user)
#
#  Output:
#     Updates the correct pet’s energy.
#     Prints “Energy increased by X units.”
#     Prints a warning if the new energy exceeds MEL.
#
#  Typical call inside the main loop:
#       li   $a0,1          # choose Pet A
#       move $a1,$t0        # n from input
#       jal  handle_EP
#
############################################################

        .data
msg_ep_add:   .asciiz "Energy increased by "
msg_units:    .asciiz " units.\n"
msg_capped:   .asciiz "Error, maximum energy level reached! Capped to the Max.\n"
msg_petA:     .asciiz "[Pet A] "
msg_petB:     .asciiz "[Pet B] "

        .text
        .globl handle_EP

############################################################
#  handle_EP  –  main routine for Entertain / Pet commands
############################################################
handle_EP:
        # 1️⃣  Compute delta = 2 × n  (left shift by 1 bit)
        sll   $t0,$a1,1

        # 2️⃣  Select which pet to update
        beq   $a0,1,petA_branch
        beq   $a0,2,petB_branch
        jr    $ra                 # invalid pet ID → return

# ----------  PET A ----------------------------------------
petA_branch:
        addu  $s0,$s0,$t0         # current_energy += 2 × n
        ble   $s0,$s2,ok_petA     # skip if ≤ MEL
        move  $s0,$s2             # cap to MEL
        li    $v0,4 ; la $a0,msg_capped ; syscall
ok_petA:
        li    $v0,4   ; la $a0,msg_petA ; syscall
        jal   print_increase
        jr    $ra

# ----------  PET B ----------------------------------------
petB_branch:
        addu  $s1,$s1,$t0
        ble   $s1,$s2,ok_petB
        move  $s1,$s2
        li    $v0,4 ; la $a0,msg_capped ; syscall
ok_petB:
        li    $v0,4   ; la $a0,msg_petB ; syscall
        jal   print_increase
        jr    $ra


############################################################
#  print_increase  –  shared sub-routine to print the gain
#  Input:
#     $t0 = delta (energy increase value)
############################################################
print_increase:
        li    $v0,4
        la    $a0,msg_ep_add
        syscall

        li    $v0,1
        move  $a0,$t0
        syscall

        li    $v0,4
        la    $a0,msg_units
        syscall

        jr    $ra

