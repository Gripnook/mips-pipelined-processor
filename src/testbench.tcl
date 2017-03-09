proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/testbench/clock
    add wave -position end sim:/testbench/reset
    add wave -position end sim:/testbench/dut/pc
    add wave -position end sim:/testbench/dut/if_npc
    add wave -position end sim:/testbench/dut/id_opcode
    add wave -position end sim:/testbench/dut/id_funct
    add wave -position end sim:/testbench/dut/id_target
    add wave -position end sim:/testbench/dut/id_rs_addr
    add wave -position end sim:/testbench/dut/id_rt_addr
    add wave -position end sim:/testbench/dut/id_immediate
    add wave -position end sim:/testbench/dut/id_branch_taken
    add wave -position end sim:/testbench/dut/id_branch_target
    # Performance counters
    add wave -position end -radix 10 sim:/testbench/dut/memory_access_stall_count
    add wave -position end -radix 10 sim:/testbench/dut/data_hazard_stall_count
    add wave -position end -radix 10 sim:/testbench/dut/branch_hazard_stall_count
}

vlib work

;# Compile components
vcom -2008 MIPS_encoding.vhd
vcom -2008 memory.vhd
vcom -2008 registers.vhd
vcom -2008 alu.vhd
vcom -2008 hazard_detector.vhd
vcom -2008 processor.vhd
vcom -2008 testbench.vhd

;# Start simulation
vsim -t ps testbench

;# Load program.txt into the instruction memory
mem load -infile program.txt -format bin -filldata 0 /testbench/dut/instruction_cache/ram_block

;# Initialize data memory with zeros
mem load -filldata 0 /testbench/dut/data_cache/ram_block

;# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run
run 1us

;# Save the memory and register file to files
mem save -outfile memory.txt -format bin -wordsperline 1 -noaddress /testbench/dut/data_cache/ram_block
mem save -outfile register_file.txt -format bin -wordsperline 1 -noaddress /testbench/dut/register_file/registers
