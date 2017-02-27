proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/alu_tb/a
    add wave -position end sim:/alu_tb/b
    add wave -position end sim:/alu_tb/opcode
    add wave -position end sim:/alu_tb/shamt
    add wave -position end sim:/alu_tb/funct
    add wave -position end sim:/alu_tb/alu_output
}

vlib work

;# Compile components
vcom -2008 alu.vhd
vcom -2008 alu_tb.vhd

;# Start simulation
vsim -t ps alu_tb

;# Generate a clock with 1 ns period
#force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run
run 10us
