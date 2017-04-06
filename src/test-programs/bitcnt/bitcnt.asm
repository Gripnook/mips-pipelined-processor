# bitcnt.asm

# $1 => x
# $2 => mask
# $3 => cnt (result)
# $4 => i
# $5 => 32
# $6 => i < 32
# $7 => x & mask
# $8 => 1
# $9 => x & mask > 0
# $20 => data section address

addi $20, $0, 2000          # Initializing the beginning of Data Section address in memory
addi $5, $0, 32             # Constant 32
addi $8, $0, 1              # Constant 1

# Prepare arguments
# ------------------------------------------------------------------------------
addi $1, $0, 96             # Input x = 96
jal bitcnt                  # Jump to function
sw $3, 0($20)               # Save the result in memory

addi $10, $3, 0             # Save result to reg 10

# ------------------------------------------------------------------------------
addi $1, $0, 7              # Input x = 7
jal bitcnt                  # Jump to function
sw $3, 4($20)               # Save the result in memory

addi $11, $3, 0             # Save result to reg 11

# ------------------------------------------------------------------------------
addi $1, $0, 345            # Input x = 345
jal bitcnt                  # Jump to function
sw $3, 8($20)               # Save the result in memory

addi $12, $3, 0             # Save result to reg 12

# ------------------------------------------------------------------------------
addi $1, $0, 23422          # Input x = 23422
jal bitcnt                  # Jump to function
sw $3, 12($20)              # Save the result in memory

addi $13, $3, 0             # Save result to reg 13

# ------------------------------------------------------------------------------
addi $1, $0, 20             # Input x = 20
jal bitcnt                  # Jump to function
sw $3, 16($20)              # Save the result in memory

addi $14, $3, 0             # Save result to reg 14

# ------------------------------------------------------------------------------
addi $1, $0, 18978          # Input x = 18978
jal bitcnt                  # Jump to function
sw $3, 20($20)              # Save the result in memory

addi $15, $3, 0             # Save result to reg 15

# ------------------------------------------------------------------------------

EoP:    beq  $0, $0, EoP    # End of program (infinite loop)

# Function body
bitcnt:    addi $2, $0, 1   # mask = 1
           add  $3, $0, $0  # cnt = 0
           add  $4, $0, $0  # i = 0

loop:   slt  $6, $4, $5     # i < 32
        bne  $6, $8, quit   # if(!(i < 32))
        and  $7, $1, $2     # x & mask
        slt  $9, $0, $7     # (x & mask) > 0
        bne  $9, $8, b1     # if (!((x & mask) > 0))
        addi $3, $3, 1      # cnt = cnt + 1
b1:     sll  $2, $2, 1      # mask = mask << 1
        addi $4, $4, 1      # i = i + 1
        j loop              # repeat the loop
quit:   jr $31
