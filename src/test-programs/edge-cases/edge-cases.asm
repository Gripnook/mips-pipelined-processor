# This program tests some edge cases that don't usually come up but can cause problems
# if hazard detection and forwarding aren't implemented correctly.

        addi $16, $0, 2000      # Initializing the beginning of Data Section address in memory
        jal  empty              # Test that hazard detection and forwarding is implemented correctly for jal
        lui  $17, 15258         # Load the upper part of 1,000,000,000 into the register
        ori  $17, $17, 51712    # Load the lower part of 1,000,000,000 into the register
        sw   $17, 0($16)        # Store 1,000,000,000 to memory

EoP:    beq  $0, $0, EoP        # End of program (infinite loop)

# Does nothing. This tests that jal correctly writes $ra before it is used by the function.
# If the implementation is incorrect, $ra will contain 0 and cause an infinite loop.
empty:  jr   $31                # Return to caller
