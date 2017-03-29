proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/alu_tb/a
    add wave -position end sim:/alu_tb/b
    add wave -position end sim:/alu_tb/opcode
    add wave -position end sim:/alu_tb/shamt
    add wave -position end sim:/alu_tb/funct
    add wave -position end sim:/alu_tb/alu_result
}

vlib work

;# Compile components
vcom -2008 mips_instruction_set.vhd
vcom -2008 alu/alu.vhd
vcom -2008 alu/alu_tb.vhd

;# Start simulation
vsim -t ps alu_tb

;# Add the waves
AddWaves

;# Run
run 10us
