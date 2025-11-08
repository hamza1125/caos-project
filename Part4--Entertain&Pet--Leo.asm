############################################################
#  TASK 4 – Entertain (E n) & Pet (P n) – Single-Pet Logic
#  Author: Leo Li (COMP0068 Digital Pet Project 2025/26)
#
#  Group Conventions (agreed):
#    • One pet only.
#    • Command parameter n is passed in $a0.
#    • Register layout:
#         $s0 = current energy
#         $s1 = EDR (energy depletion rate)        ; unused here
#         $s2 = MEL (maximum energy level)
#         $s3 = IEL (initial energy level)         ; unused here
#
#  Effect of E n / P n:
#    • Increase energy by (2 × n).
#    • If energy exceeds MEL, cap to MEL and print a warning.
#
#  Call contract:
#    • Input : $a0 = n (non-negative integer)
#    • State : $s0..$s3 as above, set elsewhere (init/main)
#    • Output: $s0 updated; prints messages
#    • Clobbers: $t0, $t1, $v0, $a0
#
#  Usage from main loop (example):
#      # parser extracts n into $a0
#      jal handle_EP
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
#   Input : $a0 = n
#   State : $s0=current, $s1=EDR, $s2=MEL, $s3=IEL
#   Notes : This routine does NOT modify $s1/$s2/$s3.
############################################################
handle_EP:
        # Preserve input n before any syscalls reuse $a0
        move  $t1, $a0              # t1 = n

        # Compute delta = 2 * n (shift-left by 1)
        sll   $t0, $t1, 1           # t0 = delta

        # current_energy += delta
        addu  $s0, $s0, $t0

        # If current_energy > MEL -> cap and warn
        ble   $s0, $s2, ep_print
        move  $s0, $s2
        li    $v0, 4
        la    $a0, msg_cap
        syscall

ep_print:
        # Print: "Energy increased by "
        li    $v0, 4
        la    $a0, msg_ep_add
        syscall

        # Print the delta value
        li    $v0, 1
        move  $a0, $t0
        syscall

        # Print: " units.\n"
        li    $v0, 4
        la    $a0, msg_units
        syscall

        jr    $ra
