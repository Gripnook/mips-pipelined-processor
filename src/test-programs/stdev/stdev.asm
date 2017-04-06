#############################################
#This program takes a set of data points and
#calculates their standard deviation. The
#dataset size should be the first element in
#memory followed by the dataset. Since there
#are no FPU in the CPU results are optimal
#when the mean is an integer.


addi $7, $0, 2000 #Start of data memory address

#########################
addi $1, $0, 8 #Enter dataset size here
sw $1, 0($7)   #Store the size of the dataset in base memory address
#########################

#######Dataset#######
addi $1, $0, 1
sw $1, 4($7)

addi $1, $0, 2
sw $1, 8($7)

addi $1, $0, 3
sw $1, 12($7)

addi $1, $0, 4
sw $1, 16($7)

addi $1, $0, 5
sw $1, 20($7)

addi $1, $0, 6
sw $1, 24($7)

addi $1, $0, 7
sw $1, 28($7)

addi $1, $0, 12
sw $1, 32($7)
#########################

start: lw $1, 0($7)     #load dataset size into $1
    addi $2, $7, 4      #initialize offset
    addi $3, $0, 0      #initialize counter
    jal sum             #Sums together all data points and stores result in $r5
    jal div             #Divides result in $r5 by the dataset size and store result in $r6. $r6 is the mean
    jal sub             #Subtracts each data point by the mean
    jal square          #Takes the square of each new element
    jal sum             #Sums together all the new data points and stores result in $r5
    jal div             #Divides result in $r5 by the dataset size and stores result in $r6
    jal sqrt            #Take the square root of result in $r6 and stores result in $r9
    j eop               #infinite loop


#########################
sum: addi $2, $7, 4
    addi $3, $0, 0

sumloop: beq $1, $3, sumreturn
    lw $4, 0($2)
    add $5, $5, $4
    addi $3, $3, 1
    addi $2, $2, 4
    j sumloop

sumreturn: jr $31
#########################


#########################
div: div $5, $1
    mflo $6
    addi $2, $0, 4
    addi $3, $0, 0
    jr $31
#########################


#########################
sub: addi $2, $7, 4
    addi $3, $0, 0

subloop: beq $1, $3, subreturn
    lw $4, 0($2)
    sub $5, $4, $6
    sw $5, 0($2)
    addi $2, $2, 4
    addi $3, $3, 1
    j subloop

subreturn: jr $31
#########################


#########################
square: addi $2, $7, 4
    addi $3, $0, 0

sqrloop: beq $1, $3, sqrreturn
    lw $4, 0($2)
    mult $4, $4
    mflo $5
    sw $5, 0($2)
    addi $2, $2, 4
    addi $3, $3, 1
    j sqrloop

sqrreturn: jr $31
#########################


#########################
sqrt:   addi $8, $0, 1      #constant 1
	addi $1, $0, 0          #initialize counter R1 to 0
        add $2, $0, $6      #Load x into R2
        add $6, $0, $0      #clear registers
        add $5, $0, $0      #clear registers

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
      	jr $31		        #store result in memory
#########################


eop:    beq $1, $1, eop     #infinite loop
