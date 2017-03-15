###############################################
# This program calculates the square root of a
# perfect square. The variable is placed in $R2
# and the output is available at $R9 and in memory

#int sqrt(int x) {
#   int i = 0;
#   while (i*i <= x)
#       ++i;
#   return i-1;
#}

#$1 -> counter i
#$2 -> variable x
#$3 -> i^2
#$4 -> 1 if i^2 < x
#$5 -> 0 if i^2 = x
#$8 -> constant 1
#$9 -> result

addi $11, $0, 2000          #Initializing the beginning of data section address in memory
addi $8, $0, 1              #constant 1

main:   addi $1, $0, 0      #initialize counter R1 to 0
        addi $2, $0, 36     #Load x into R2

compare: mult $1, $1        #i * i
        mflo $3             #$3 = i*i
        slt $4, $3, $2      #$4 = 1 if i^2 < x
        sub $5, $2, $3      #$5 = 0 if i^2 = x
        beq $5, $0, loop    #loop if i^2 = x
        beq $4, $8, loop    #loop if i^2 < x
        j return            #break from loop

loop:   addi $1, $1, 1      #increment counter
        j compare           #loop back

return: addi $9, $1, -1     #store result in R9
        sw   $9, 0($11)     #store result in memory
eop:    beq $1, $1, eop     #infinite loop
