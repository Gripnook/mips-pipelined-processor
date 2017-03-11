proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/testbench/clock
    add wave -position end sim:/testbench/reset
    # Processor state
    add wave -position end sim:/testbench/dut/pc
    add wave -position end sim:/testbench/dut/if_npc
    add wave -position end sim:/testbench/dut/id_opcode
    add wave -position end sim:/testbench/dut/id_funct
    add wave -position end sim:/testbench/dut/id_rs_addr
    add wave -position end sim:/testbench/dut/id_rt_addr
    add wave -position end sim:/testbench/dut/id_immediate
    add wave -position end sim:/testbench/dut/id_branch_taken
    # Stall signals
    add wave -position end sim:/testbench/dut/if_waitrequest
    add wave -position end sim:/testbench/dut/mem_waitrequest
    add wave -position end sim:/testbench/dut/data_hazard_stall
    # Performance counters
    add wave -position end -radix 10 sim:/testbench/dut/memory_access_stall_count
    add wave -position end -radix 10 sim:/testbench/dut/data_hazard_stall_count
    add wave -position end -radix 10 sim:/testbench/dut/branch_hazard_stall_count
}

vlib work

# Compile components
vcom mips_instruction_set.vhd
vcom memory.vhd
vcom registers.vhd
vcom alu.vhd
vcom hazard_detector.vhd
vcom processor.vhd
vcom testbench.vhd

# Start simulation
vsim -t ps testbench

# Load program into the instruction memory
mem load -infile program.txt -format bin -filldata 0 /testbench/dut/instruction_cache/ram_block

# Initialize data memory with zeros
mem load -filldata 0 /testbench/dut/data_cache/ram_block

# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

# Add the waves
AddWaves

# Run
run 10us

# Save the memory and register file to files
mem save -outfile memory.txt -format bin -wordsperline 1 -noaddress /testbench/dut/data_cache/ram_block
mem save -outfile register_file.txt -format bin -wordsperline 1 -noaddress /testbench/dut/register_file/registers
