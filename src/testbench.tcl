proc AddWaves {} {
    # Add waves we're interested in to the Wave window
    add wave -position end sim:/testbench/clock
    add wave -position end sim:/testbench/reset
    # Processor state
    add wave -position end sim:/testbench/dut/done
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
    # Forwarding signals
    add wave -position end sim:/testbench/dut/fwd_id_rs
    add wave -position end sim:/testbench/dut/fwd_id_rt
    add wave -position end sim:/testbench/dut/fwd_ex_rs
    add wave -position end sim:/testbench/dut/fwd_ex_rt
    add wave -position end sim:/testbench/dut/fwd_mem_rt
    add wave -position end sim:/testbench/dut/fwd_ex_ready
    add wave -position end sim:/testbench/dut/fwd_ex_result
    add wave -position end sim:/testbench/dut/fwd_mem_ready
    add wave -position end sim:/testbench/dut/fwd_mem_result
    add wave -position end sim:/testbench/dut/fwd_wb_ready
    add wave -position end sim:/testbench/dut/fwd_wb_result
    # Performance counters
    add wave -position end -radix 10 sim:/testbench/dut/instruction_count
    add wave -position end -radix 10 sim:/testbench/dut/i_memory_access_stall_count
    add wave -position end -radix 10 sim:/testbench/dut/d_memory_access_stall_count
    add wave -position end -radix 10 sim:/testbench/dut/data_hazard_stall_count
    add wave -position end -radix 10 sim:/testbench/dut/branch_hazard_stall_count
}

vlib work

# Compile components
vcom mips_instruction_set.vhd
vcom cache/cache_controller.vhd
vcom cache/cache_block.vhd
vcom cache/cache.vhd
vcom cache/memory.vhd
vcom cache/arbiter.vhd
vcom branch_prediction/bp_predict_not_taken.vhd
vcom branch_prediction/bp_predict_taken.vhd
vcom branch_prediction/bp_1bit_predictor.vhd
vcom branch_prediction/bp_2bit_predictor.vhd
vcom branch_prediction/bp_correlating_2_2.vhd
vcom branch_prediction/bp_tournament_2_2.vhd
vcom branch_prediction/branch_prediction.vhd
vcom registers.vhd
vcom alu/alu.vhd
vcom hazards/hazard_detector.vhd
vcom processor.vhd
vcom testbench.vhd

# Start simulation
vsim -t ps testbench

# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

# Add the waves
AddWaves

# Load program into main memory
mem load -infile program.txt -format bin -filldata 0 /testbench/dut/mem/ram_block

# Run
run 20us

# Save the memory and register file to files
mem save -outfile memory.txt -format bin -wordsperline 1 -noaddress /testbench/dut/mem/ram_block
mem save -outfile register_file.txt -format bin -wordsperline 1 -noaddress /testbench/dut/register_file/registers
