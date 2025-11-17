############################################################
# Part4_handle_EP_Leo – Entertain / Pet: energy += 2*n
# Input : $a0 = n  (non-negative integer)
# State : $s0 = current energy
# Output: $v0 = delta (2*n), $s0 updated
# Notes: Pure arithmetic only. 
#        No prints, no MEL cap, no RAM mirror (handled in main loop).
############################################################

        .text
        .globl Part4_handle_EP_Leo

Part4_handle_EP_Leo:
        sll   $t0, $a0, 1       # t0 = 2*n
        addu  $s0, $s0, $t0     # s0 += 2*n
        move  $v0, $t0          # return delta to caller (main loop)
        jr    $ra               # return
