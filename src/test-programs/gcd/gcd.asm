# Pseudo-code:
# int gcd(int x, int y) {
# if (x > y)
# swap(x, y);
# return x == 0 ? y : gcd(y % x, x);
# }

        addi $11, $0, 2000          # initializing the beginning of Data Section address in memory
        addi $29, $0, 32764

test:   addi $4, $0, 22866          # x 103*222
        addi $5, $0, 9991           # y 103*97
        sw   $4, 0($11)
        sw   $5, 4($11)
        addi $4, $0, 99             #memory tests
        addi $5, $0, 151
        lw   $4, 0($11)
        lw   $5, 4($11)

        jal gcd
        sw   $2, 8($11)

EoP:    beq  $11, $11, EoP          #end of program (infinite loop)

gcd:    slt $8, $5, $4              # swap condition
        bne $8, $0, swap

        addi $29, $29, -12
        sw $5, 8($29)
        sw $4, 4($29)
        sw $31, 0($29)
        or $2, $0, $5               # y into output
        beq $4, $0, gcd_rt          # return if x == 0
        or $8, $0, $5
        or $5, $0, $4
        div $8, $4                  # divide y by x
        mfhi $4                     # take remainder as x
        jal gcd
        lw $5, 8($29)
        lw $4, 4($29)
        j gcd_rt

swap:   or $8, $0, $4               # put x into temp
        or $4, $0, $5               # put y into x
        or $5, $0, $8               # put temp into y
        j gcd

gcd_rt: lw $31, 0($29)
        addi $29, $29, 12
        jr $31
