
############################################################
#  TASK 4 – Entertain (E n) & Pet (P n) – Single-Pet Logic
#  Author: Lele Li (COMP0068 Digital Pet Project 2025/26)
#
#  Scope (this file only contains YOUR part):
#    • One pet only (as per team decision).
#    • Implements the shared logic for E/P commands:
#        energy += 2 × n, then cap at MEL if exceeded.
#    • Printing matches coursework wording.
#
#  Contract with main program:
#    • State registers (set/maintained elsewhere):
#         $s0 = current_energy
#         $s1 = MEL  (maximum energy level)
#    • Inputs for this routine:
#         $a1 = n   (positive integer parsed by the command parser)
#
#  Usage example in main loop (pseudo):
#       move $a1, n
#       jal  handle_EP
#
############################################################

        .data
msg_ep_add:   .asciiz "Energy increased by "
msg_units:    .asciiz " units.\n"
msg_cap:      .asciiz "Error, maximum energy level reached! Capped to the Max.\n"

        .text
        .globl handle_EP

############################################################
# handle_EP – apply Entertain/Pet effect (+2×n with MEL cap)
#   Input : $a1 = n
#   State : $s0 = current_energy, $s1 = MEL
#   Output: $s0 updated; prints gain and cap warning if capped
#   Clobbers: $t0, $v0, $a0
############################################################
handle_EP:
        # delta = 2 * n  (left shift by 1)
        sll   $t0, $a1, 1

        # current_energy += delta
        addu  $s0, $s0, $t0

        # if current_energy > MEL → cap and warn
        ble   $s0, $s1, ep_print
        move  $s0, $s1
        li    $v0, 4
        la    $a0, msg_cap
        syscall

ep_print:
        # "Energy increased by "
        li    $v0, 4
        la    $a0, msg_ep_add
        syscall
        # print delta
        li    $v0, 1
        move  $a0, $t0
        syscall
        # " units.\n"
        li    $v0, 4
        la    $a0, msg_units
        syscall

        jr    $ra
