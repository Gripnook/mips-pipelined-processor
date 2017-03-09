proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/processor_tb/clock
    add wave -position end sim:/processor_tb/reset
    add wave -position end sim:/processor_tb/dut/pc
    add wave -position end sim:/processor_tb/dut/pc_enable
}

vlib work

;# Compile components
vcom -2008 MIPS_encoding.vhd
vcom -2008 memory.vhd
vcom -2008 registers.vhd
vcom -2008 alu.vhd
vcom -2008 hazard_detector.vhd
vcom -2008 processor.vhd
vcom -2008 processor_tb.vhd

;# Start simulation
vsim -t ps processor_tb

;# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run
run 10us
