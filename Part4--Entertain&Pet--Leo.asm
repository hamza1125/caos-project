############################################################
#  POD4 – Entertain (E n) & Pet (P n) – Single-Pet Logic
#  Author : Leo Li (COMP0068 Digital Pet Project 2025/26)
#
#  Team Conventions:
#    • One pet only
#    • Command parameter n is passed in $a0
#    • Registers:
#         $s0 = current energy
#         $s1 = EDR (energy depletion rate)        ; unused here
#         $s2 = MEL (maximum energy level)
#         $s3 = IEL (initial energy level)         ; unused here
#
#  Effect of E n / P n:
#    • energy += (2 × n)
#    • if energy > MEL: cap to MEL and print a warning
#
#  Call contract:
#    • Input : $a0 = n  (non-negative integer from parser)
#    • State : $s0..$s3 prepared elsewhere (init/main)
#    • Output: $s0 updated; user messages printed
#    • Clobbers: $t0, $t1, $t2, $v0, $a0
#
#  Integration note:
#    • This routine mirrors $s0 into RAM symbol `CurrentEnergy`
#      so main_loop's per-second depletion (which uses RAM) stays in sync.
#    • If `CurrentEnergy` is defined in another file, remove the
#      duplicate definition below to avoid multiple-definition errors.
############################################################

        .data
# ---- Strings ------------------------------------------------
msg_ep_add:     .asciiz "Energy increased by "
msg_units:      .asciiz " units.\n"
msg_cap:        .asciiz "Error, maximum energy level reached! Capped to the Max.\n"

# ---- Shared state in RAM (remove if already defined elsewhere)
CurrentEnergy:  .word   0

        .text
        .globl handle_EP

############################################################
# handle_EP – apply Entertain/Pet effect (+2×n with MEL cap)
#   Input : $a0 = n
#   State : $s0=current, $s1=EDR, $s2=MEL, $s3=IEL
#   Notes : Keeps RAM mirror `CurrentEnergy` up to date.
############################################################
handle_EP:
        # 1) Preserve n; syscalls also use $a0 so don't lose it.
        move  $t1, $a0              # t1 = n

        # 2) delta = 2 * n  (shift-left by 1 is faster than mul)
        sll   $t0, $t1, 1           # t0 = delta

        # (Optional) If delta == 0, skip printing to avoid noise
        beq   $t0, $zero, ep_update

        # 3) current += delta
        addu  $s0, $s0, $t0

        # 4) Cap to MEL if exceeded; warn once
        ble   $s0, $s2, ep_print
        move  $s0, $s2              # cap to MEL
        li    $v0, 4                # print_string
        la    $a0, msg_cap
        syscall

ep_print:
        # 5) Print "Energy increased by "
        li    $v0, 4
        la    $a0, msg_ep_add
        syscall

        #    then print the delta integer
        li    $v0, 1                # print_int
        move  $a0, $t0
        syscall

        #    then " units.\n"
        li    $v0, 4
        la    $a0, msg_units
        syscall

ep_update:
        # 6) Mirror $s0 to RAM so the main loop sees the new value
        la    $t2, CurrentEnergy
        sw    $s0, 0($t2)

        jr    $ra
