# This program generates a specified number of prime numbers.
# It starts by setting 2 as a prime, then checks odd numbers for divisibility
# by primes already found in order to find new primes.

        addi $16, $0, 2000      # Initializing the beginning of Data Section address in memory
        addi $23, $16, 0        # Address of current prime
        addi $17, $0, 16        # Number of primes to generate
        addi $18, $0, 0         # Number of primes generated so far

        addi $19, $0, 2         # 2 is a special case
        sw   $19, 0($23)        # Store prime
        addi $18, $18, 1        # Increment number of primes generated
        addi $23, $23, 4        # Increment address of current prime

        addi $19, $0, 3         # Set first prime candidate

L0:     beq  $17, $18, EoP      # End when all primes are generated
        addi $4, $19, 0         # Set prime candidate as function input
        addi $5, $16, 0         # Set start address of primes as function input
        addi $6, $23, 0         # Set end address of primes as function input
        jal  prime              # Function call
        beq  $2, $0, L1         # Go to end of loop if not prime
        sw   $19, 0($23)        # Store prime
        addi $18, $18, 1        # Increment number of primes generated
        addi $23, $23, 4        # Increment address of the current prime
L1:     addi $19, $19, 2        # Increment prime candidate
        j    L0                 # Restart loop

EoP:    beq  $0, $0, EoP        # End of program (infinite loop)

# Checks if $4 is prime by comparing to all primes in addresses [$5,$6)
# Returns value in $2
prime:  addi $2, $0, 1          # Default is true
L2:     lw   $8, 0($5)          # Load next prime
        addi $5, $5, 4          # Increment address
        div  $4, $8             # Divide candidate by prime
        mfhi $8                 # Get remainder
        beq  $8, $0, L3         # If divisible by prime, then not prime
        beq  $5, $6, return     # Reached the end of primes
        j    L2                 # Loop again
L3:     addi $2, $0, 0          # Set return value to not prime
return: jr   $31                # Return to caller
