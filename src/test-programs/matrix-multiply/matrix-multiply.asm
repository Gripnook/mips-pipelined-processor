# This program fills an n by n matrix A with Fibonacci numbers, then computes the matrix product A*A.

            addi $4,  $0,  4    # size of square matrix

            # number of generating Fibonacci-numbers
            mult $4,  $4
            mflo $16
            addi $10, $16, 0

            addi $1,  $0,  1    # initializing Fib(-1) = 0
            addi $2,  $0,  1    # initializing Fib(0) = 1
            addi $11, $0,  2000 # initializing the beginning of Data Section address in memory
            addi $15, $0,  4    # word size in byte

loop:       addi $3,  $2,  0    # temp = Fib(n-1)
            add  $2,  $2,  $1   # Fib(n)=Fib(n-1)+Fib(n-2)
            addi $1,  $3,  0    # Fib(n-2)=temp=Fib(n-1)
            mult $10, $15       # $lo=4*$10, for word alignment
            mflo $12            # assume small numbers
            add  $13, $11, $12  # Make data pointer [2000+($10)*4]
            sw   $2, -4($13)    # Mem[$10+2000-4] <-- Fib(n)
            addi $10, $10, -1   # loop index
            bne  $10, $0,  loop

            # Pass matrix parameters
            addi $5,  $11, 0
            addi $6,  $11, 0
            sll  $7,  $16, 2
            add  $7,  $11, $7

            jal  multiply
EoP:        beq  $0, $0, EoP    # End of program (infinite loop)

# n  = $4
# &a = $5
# &b = $6
# &c = $7
#
# Pseudo-code:
# for (int i = 0; i < n; ++i) {
#   for (int j = 0; j < n; ++j) {
#     c[i][j] = 0;
#     for (int k = 0; k < n; ++k) {
#       c[i][j] += a[i][k] * b[k][j];
#     }
#   }
# }
multiply:   sll  $16, $4,  2
            addi $8,  $0,  0    # i = 0
loop1:      beq  $8,  $16, end1
            addi $9,  $0,  0    # j = 0
loop2:      beq  $9,  $16, end2
            addi $10, $0,  0    # k = 0
            addi $11, $0,  0    # c[i][j] = 0
loop3:      beq  $10, $16, end3

            # Compute &a[i][k]
            mult $10, $4
            mflo $13
            add  $12, $5, $8
            add  $12, $12, $13

            # Load a[i][k]
            lw   $14, 0($12)

            # Compute &b[k][j]
            mult $9,  $4
            mflo $13
            add  $12, $6, $10
            add  $12, $12, $13

            # Load b[k][j]
            lw   $15, 0($12)

            # c[i][j] += a[i][k] * b[k][j]
            mult $14, $15
            mflo $14
            add  $11, $11, $14

            # ++k
            addi $10, $10, 4

            j    loop3

            # Compute &c[i][j]
end3:       mult $9,  $4
            mflo $13
            add  $12, $7,  $8
            add  $12, $12, $13

            # Store c[i][j]
            sw   $11, 0($12)

            # ++j
            addi $9,  $9,  4

            j    loop2

            # ++i
end2:       addi $8,  $8,  4

            j    loop1

end1:       jr   $31
