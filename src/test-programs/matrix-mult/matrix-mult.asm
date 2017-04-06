#This mips assembly program multiplies 2 mxn matrices of desired size. The size can
#be set on lines 29, 33 & 46, 49. Note that the m's must match in dimension. The result
#is stored in memory at address 3500. The first 2 words stored are the dimensions of
#the resulting matrix and the proceeding data is the multiplication result

    addi $1, $0, 100 #Start of data memory address
    addi $2, $0, 500 #Start of Matrix data A
    addi $3, $0, 1000 #start of Matrix data B
    addi $4, $0, 1500 #start of Result Matrix
    addi $5, $0, 2000 #start of scratch space
    add $6, $0, $0 #number of elements in A
    add $7, $0, $0 #number of elements in B

    addi $10, $0, 0 #counter for loops
    addi $11, $2, 8 #memory A offset
    addi $12, $3, 8 #memory B offset
    addi $13, $4, 8 #memory Result offset
    addi $14, $5, 0 #scratch space offset
    addi $15, $0, 0 #rows of A
    addi $16, $0, 0 #cols of B
    addi $17, $0, 0 #loop max for multiply
    addi $18, $0, 0 #scratch register
    addi $19, $0, 0 #running sum
    addi $20, $0, 0 #matrix column counter
    addi $21, $0, 1 #matrix row counter


#############Size of Matrix A n x m
    addi $15, $0, 4 #n
    sw $15, -8($2)
    sw $15, 0($4)

    addi $17, $0, 4 #m must match below
    sw $17, -4($2)
#############

#############Store number of elements in A in $6
    lw $18, -8($2)
    lw $19, -4($2)
    mult $18, $19
    mflo $18
    add $6, $0, $18
#############

#############Size of Matrix B m x n
    addi $17, $0, 4 #m must match above
    sw $17, -8($3)

    addi $16, $0, 4 #n
    sw $16, -4($3)
    sw $16, 4($4)
#############

#############Store number of elements in B in $7
    lw $18, -8($3)
    lw $19, -4($3)
    mult $18, $19
    mflo $18
    add $7, $0, $18
#############

###################
    addi $18, $0, 1         #number to populate matrix with
    addi $11, $2, 0         #initialize offset counter
populateA: beq $10, $6, s1  #if array is full branch
    sw $18, 0($11)          #store value into array
    addi $10, $10, 1        #increment counter
    addi $11, $11, 4        #increment memory offset A
    j populateA             #loop back

s1: addi $18, $0, 1
    addi $12, $3, 0
    addi $10, $0, 0
populateB: beq $10, $6, s2
    sw $18, 0($12)
    addi $10, $10, 1
    addi $12, $12, 4
    j populateB
####################

s2: addi $11, $2, 0     #initialize A offset counter
    addi $12, $3, 0     #initialize B offset counter
    addi $14, $5, 0     #initialize scratch space offset counter
    addi $10, $0, 0     #initialize loop counter
    addi $20, $0, 1     #initialize matrix column counter

mult: beq $10, $17, s3
    lw $18, 0($11)      #load element from A to multiply
    lw $19, 0($12)      #load element from B to multiply
    mult $18, $19       #multiply both elements
    mflo $18
    sw $18, 0($14)      #store result in scratch space
    addi $19, $0, 0     #clear register
    addi $11, $11, 4    #increment memory offset A
    addi $12, $12, 4    #increment memory offset B
    addi $14, $14, 4    #increment scratch space offset
    addi $10, $10, 1    #increment counter
    j mult

s3: addi $14, $5, 0     #initialize scratch space offset counter
    addi $10, $0, 0     #initialize loop counter

add: beq $10, $17, s4   #if all elements are added jump
    lw $18, 0($14)      #load first mult to add from scratch space
    add $19, $19, $18   #add to running sum
    addi $14, $14, 4    #increment scratch space address
    addi $10, $10, 1    #increment loop counter
    j add

s4: sw $19, 0($13)
    addi $13, $13, 4    #increment result address pointer
    addi $19, $0, 0     #clear running sum
    beq $20, $16, s5    #check if all cols of B were traversed
    addi $20, $20, 1	#increment matrix column counter
    addi $18, $0, 4     #constant 4
    mult $18, $17       #get number of bytes to offset by
    mflo $18
    add $12, $3, $18    #move pointer to next col in B
    addi $11, $2, 0     #move pointer to start of row in A
    addi $10, $0, 0     #reset counter
    addi $14, $5, 0     #reset scratch space pointer
    j mult

s5: addi $12, $3, 0     #move pointer to first col in B
    addi $18, $0, 4     #constant 4
    mult $17, $18       #multiply the amount of A cols by 4 bytes
    mflo $18
    add $2, $2, $18     #move pointer to next row of A #modify base address pointer for A to new row
    beq $21, $15, s6
    addi $21, $21, 1    #increment row counter
    addi $20, $0, 1     #reset columun counter
    addi $10, $0, 0     #reset counter
    addi $14, $5, 0     #reset scratch space pointer
    j mult
s6: j s6
