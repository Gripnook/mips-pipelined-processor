# This script runs all the benchmarks in the test-programs directory and checks that the outputs
# of the processor are the same as the expected outputs given for each benchmark.
# This scripts requires the diff program to be on the system path.

vlib work

# Compile components
vcom mips_instruction_set.vhd
vcom memory.vhd
vcom registers.vhd
vcom alu/alu.vhd
vcom hazards/hazard_detector.vhd
vcom processor.vhd
vcom testbench.vhd

# Get the program names
set programs [dir /b /o:n /ad test-programs]
set programs [regexp -all -inline {\S+} $programs]

# Start simulation
vsim -t ps testbench

# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

echo Program,Memory Stall Count,Data Hazard Stall Count,Branch Hazard Stall Count

foreach program $programs {
    # Set up the results directory
    file mkdir results/$program

    # Restart the simulation
    restart -f

    # Load program into the instruction memory
    mem load -infile test-programs/$program/program.txt -format bin -filldata 0 /testbench/dut/instruction_cache/ram_block

    # Initialize data memory with zeros
    mem load -filldata 0 /testbench/dut/data_cache/ram_block

    # Run
    run 10us

    # Save the memory and register file to files
    mem save -outfile results/$program/memory.txt -format bin -wordsperline 1 -noaddress /testbench/dut/data_cache/ram_block
    mem save -outfile results/$program/register_file.txt -format bin -wordsperline 1 -noaddress /testbench/dut/register_file/registers

    echo $program,[examine -radix dec /testbench/dut/memory_access_stall_count],[examine -radix dec /testbench/dut/data_hazard_stall_count],[examine -radix dec /testbench/dut/branch_hazard_stall_count]
}

# Compare results
foreach program $programs {
    echo [diff -ws results/$program/memory.txt test-programs/$program/memory.txt]
    echo [diff -ws results/$program/register_file.txt test-programs/$program/register_file.txt]
}
