# exp.asm

# $1 => result
# $2 => y
# $3 => x
# $4 => y & 1
# $5 => 1
# $6 => data section address

addi $6, $0, 2000           # Initializing the beginning of Data Section address in memory
addi $5, $0, 1              # Constant 1

# Prepare arguments
# ------------------------------------------------------------------------------
addi $2, $0, 4              # Input y = 4
addi $3, $0, 15             # Input x = 15
jal exp                     # Jump to function
sw $1, 0($6)                # Save the result in memory

addi $10, $1, 0             # Save result to reg 10

# ------------------------------------------------------------------------------
addi $2, $0, 11             # Input y = 11
addi $3, $0, 7              # Input x = 7
jal exp                     # Jump to function
sw $1, 4($6)                # Save the result in memory

addi $11, $1, 0             # Save result to reg 11

# ------------------------------------------------------------------------------
addi $2, $0, 8              # Input y = 8
addi $3, $0, 3              # Input x = 3
jal exp                     # Jump to function
sw $1, 8($6)                # Save the result in memory

addi $12, $1, 0             # Save result to reg 12

# ------------------------------------------------------------------------------
addi $2, $0, 9              # Input y = 9
addi $3, $0, 8              # Input x = 8
jal exp                     # Jump to function
sw $1, 12($6)               # Save the result in memory

addi $13, $1, 0             # Save result to reg 13

# ------------------------------------------------------------------------------
addi $2, $0, 9              # Input y = 9
addi $3, $0, 23             # Input x = 23
jal exp                     # Jump to function
sw $1, 16($6)               # Save the result in memory

addi $14, $1, 0             # Save result to reg 14

# ------------------------------------------------------------------------------
addi $2, $0, 20             # Input y = 20
addi $3, $0, 3              # Input x = 3
jal exp                     # Jump to function
sw $1, 20($6)               # Save the result in memory

addi $15, $1, 0             # Save result to reg 15

# ------------------------------------------------------------------------------

EoP:    beq  $0, $0, EoP    # End of program (infinite loop)

# Function body
exp:    addi $1, $0, 1      # result = 1

loop:   beq  $0, $2, quit   # while(y != 0)
        andi $4, $2, 1      # k = y & 1
        bne  $4, $5, b1     # if(k != 1)
        mult $1, $3         # result * x
        mflo $1             # result = result * x
b1:     mult $3, $3         # x * x
        mflo $3             # x = x * x
        srl  $2, $2, 1      # y = y >> 1
        j loop              # repeat the loop
quit:   jr $31
