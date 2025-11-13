.eqv BUFFER_SIZE 8 #>1
.eqv MAX_NUMERIC_VALUE 2 #>0

.macro READ_INPUT (%addr, %len)
    li  $v0, 8
    la  $a0, %addr
    li  $a1, %len
    syscall
.end_macro

.data
edr: .word 1
mel: .word 15
iel: .word 5

input_buffer: .byte 0:BUFFER_SIZE

init_header: .asciiz "=== Digital Pet Simulator (MIPS32) ===\nInitializing system...\n\nPlease set parameters (press Enter for default):\nEnter Natural Energy Depletion Rate (EDR) [Default: 1]: "
init_mel: .asciiz "Enter Maximum Energy Level (MEL) [Default: 15]: "
init_iel: .asciiz "Enter Initial Energy Level (IEL) [Default: 5]: "
init_success: .asciiz "\nParameters set successfully!\n- EDR: "
init_success2: .asciiz " units/sec\n- MEL: "
init_success3: .asciiz " units\n- IEL: "
init_success4: .asciiz " units\n\nYour Digital Pet is alive! Current status:\n"
wrong_type_input_num: .asciiz "Invalid input: Only digits are allowed in this field; Maximum value is a 2-digit number: "
over_limit_num: .asciiz "The value cannot exceed "
under_limit_num: .asciiz "The value cannot be less than 1"
try_again: .asciiz ". Please try again: "
wrong_type_Input_cmd: .asciiz "Invalid input. Follow this format for 'F/E/P/I n' (n<100) or 'R/Q'. Please try again: " 

.text
.globl main
main:
jal gameInit

li $v0, 10
syscall

# purpose: Print startup prompts, read and store EDR/MEL/IEL via numberToMemory, echo chosen values, initialise to s registers.
# output:  v0 = 0; s1 = EDR, s2 = MEL, s0 = IEL, s3 = IEL (copy); 
# clobbers: ra (properly saved/restored)
gameInit:
	addiu $sp, $sp, -8
	sw $ra, 4($sp)
	
	li $v0, 4
	la $a0, init_header
	syscall
	la $a0, edr
	li $a1, -1
	jal numberToMemory
	move $s1, $v0
	li $v0, 4
	la $a0, init_mel
	syscall
	la $a0, mel
	li $a1, -1
	jal numberToMemory
	move $s2, $v0
	li $v0, 4
	la $a0, init_iel
	syscall
	la $a0, iel
	move $a1, $s2
	jal numberToMemory
	move $s3, $v0
	move $s0, $v0
	li $v0, 4
	la $a0, init_success
	syscall
	li $v0, 1
	move $a0, $s1
	syscall
	li $v0, 4
	la $a0, init_success2
	syscall
	li $v0, 1
	move $a0, $s2
	syscall
	li $v0, 4
	la $a0, init_success3
	syscall
	li $v0, 1
	move $a0, $s3
	syscall
	li $v0, 4
	la $a0, init_success4
	syscall
	li $v0, 0
	
	lw $ra, 4($sp)
	addiu $sp, $sp, 8
	jr $ra
#input of a0 = variable memory address, a1 max allowed value
#output v0 as the final variable value, v1 as a flag if the variable was updated
#reruns on the unsuccessful input
# purpose: Read a line, parse number; if OK store to *(a0). Empty keeps old value; If exceeds max or bad input re-prompt.
# input:   a0 = &word_to_update
# output:  v0 = final value in memory; v1 = 0 updated | 1 empty
# clobbers: ra, s0, s1 (saved/restored); uses input_buffer, READ_INPUT, parseNumber
# notes:   parseNumber enforces max 2 digits; message printed on error.
numberToMemory:
	addiu $sp, $sp, -16
	sw $ra, 12($sp)
	sw $s0, 8($sp)
	sw $s1, 4($sp)
	
	move $s0, $a0
	move $s1, $a1
	NTM_read:
		READ_INPUT (input_buffer, BUFFER_SIZE)
		la $a0, input_buffer
		jal parseNumber
		beq $v1, 2, NTM_error
		beqz $v1, NTM_bounds
		j NTM_skip
	NTM_error:
		li $v0, 4
		la $a0, wrong_type_input_num
		syscall
		j NTM_read
	NTM_bounds:
		blez $v0, NTM_hitLowerLimit
		bltz $s1, NTM_number
		bgt $v0, $s1, NTM_hitUpperLimit
		j NTM_number
	NTM_hitLowerLimit:
		li $v0, 4
		la $a0, under_limit_num
		syscall
   		li $v0, 4
		la $a0, try_again
		syscall
		j NTM_read
	NTM_hitUpperLimit:
		li $v0, 4
		la $a0, over_limit_num
		syscall
		li    $v0, 1
    		move  $a0, $s1
   		syscall
   		li $v0, 4
		la $a0, try_again
		syscall
		j NTM_read
	NTM_number:
		sw $v0, 0($s0)
		li $v1, 0
		j NTM_return
	NTM_skip:
		lw $v0, 0($s0)
		li $v1, 1
		j NTM_return
	NTM_return:
		lw $s1, 4($sp)
		lw $s0, 8($sp)
		lw $ra, 12($sp)
		addiu $sp, $sp, 16
		jr $ra

# purpose: read and parse command "F/E/P/I <num>" or "R/Q".
# input:   none (reads with READ_INPUT)
# output:  v0 = letter ('F','E','P','I','R','Q'); v1 = number or -1 if none
# clobbers: ra, s0 (saved/restored); calls parseLetter then parseNumber
# rules:   R/Q require EMPTY number; F/E/P/I require OK number.	
commandParser:
	addiu $sp, $sp, -8
    	sw    $ra, 4($sp)
    	sw    $s0, 0($sp)
    	
    	CP_read:
    		READ_INPUT (input_buffer, BUFFER_SIZE)
    		la $a0, input_buffer
    		jal parseLetter
    		beqz $v1, CP_letterOk
    	CP_error:
    		li $v0, 4
    		la $a0, wrong_type_Input_cmd
    		syscall
    		j CP_read
    	CP_letterOk:
    		move $s0, $v0
    		jal parseNumber
    		li $t3, 2
    		beq $v1, $t3, CP_error
    		move $t1, $v0
    		move $t2, $v1
    		li $t0, 'R'
    		beq $s0, $t0, CP_noNum
    		li $t0, 'Q'
    		beq $s0, $t0, CP_noNum
    		bnez $t2, CP_error
    		move $v0, $s0
    		move $v1, $t1
    		j CP_return
    	CP_noNum:
    		li $t3, 1
    		bne $t2, $t3, CP_error
    		move $v0, $s0
    		li $v1, -1
    	CP_return:
    		lw    $s0, 0($sp)
    		lw    $ra, 4($sp)
		addiu $sp, $sp, 8
		jr $ra

# purpose: Parse [spaces]* DIGITS{1..MAX_NUMERIC_VALUE} [spaces]* then '\n' or '\0'.
# input:   a0 = buf ptr (scans from here)
# output:  v0 = value; v1 = 0 ok | 1 empty | 2 error
# notes:   advances a0 internally; accepts SPACE/TAB; rejects non-digits & >MAX_NUMERIC_VALUE digits.
parseNumber:
	li $v0, 0
	li $v1, 1
	li $t7, 0
	PN_skipLeadSpace:
		lb $t0, 0($a0)
		beqz $t0, PN_emptyCase 
		beq $t0, 10, PN_emptyCase 
		beq $t0, 32, PN_leadSpaceEmpty 
		beq $t0, 9, PN_leadSpaceEmpty
		j PN_charCheck1
	PN_leadSpaceEmpty:
		addi $a0, $a0, 1
		j PN_skipLeadSpace
	PN_charCheck1:
		li $t1, '0'
		li $t3, '9'
		blt $t0, $t1, PN_errorCase
		bgt $t0, $t3, PN_errorCase
		li $t7, 1
		li $t6, 1
		addi $t0, $t0, -48 
		addu $v0, $v0, $t0
		li $t4, MAX_NUMERIC_VALUE
	PN_charCheckLoop:
    		addi $a0, $a0, 1
    		lb   $t0, 0($a0)
    		blt  $t0, $t1, PN_trailCheck
    		bgt  $t0, $t3, PN_trailCheck
    		bge $t6, $t4, PN_errorCase
		addi $t0, $t0, -48
    		mul  $v0, $v0, 10
    		addu $v0, $v0, $t0
    		addi $t6, $t6, 1
    		j PN_charCheckLoop
    	PN_trailCheck:
    		beq $t0, $zero, PN_okCase
    		beq $t0, 10, PN_okCase
    		beq $t0, 32, PN_leadTrailEmpty
    		beq $t0, 9, PN_leadTrailEmpty
    		j PN_errorCase
    	PN_leadTrailEmpty:
    		addi $a0, $a0, 1
    		lb $t0, 0($a0)
    		j PN_trailCheck    		
    	PN_okCase:
    		beqz $t7, PN_emptyCase
    		li $v1, 0
    		jr $ra
    	PN_emptyCase:
    		jr $ra
    	PN_errorCase:
    		li $v1, 2
    		jr $ra
    		
# purpose: Parse a single command letter at *a0*; accepts F,E,P,I,R,Q (case-insensitive).
# input:   a0 = buf ptr (must point at letter)
# output:  v0 = uppercase letter; v1 = 0 ok | 1 empty | 2 error
# notes:   uppercases a–z; advances a0 by 1 on success.
parseLetter:
	li $v1, 1
	lb $t0, 0($a0)
	beqz $t0, PL_return
	beq $t0, 10, PL_return
	li $t1, 'a'
	li $t2, 'z'
	blt $t0, $t1, PL_check
	bgt $t0, $t2, PL_check
	addi $t0, $t0, -32
	PL_check:
		li $t3, 'F'
		beq $t0, $t3, PL_correct
		li $t3, 'E'
		beq $t0, $t3, PL_correct
		li $t3, 'P'
		beq $t0, $t3, PL_correct
		li $t3, 'I'
		beq $t0, $t3, PL_correct
		li $t3, 'R'
		beq $t0, $t3, PL_correct
		li $t3, 'Q'
		beq $t0, $t3, PL_correct
		j PL_error
	PL_correct:
		move $v0, $t0
		li $v1, 0
		addi $a0, $a0, 1
		j PL_return
	PL_error:
		li $v1, 2
	PL_return:
		jr $ra