proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/memory_tb/clock
    add wave -position end sim:/memory_tb/address
    add wave -position end sim:/memory_tb/memread
    add wave -position end sim:/memory_tb/readdata
    add wave -position end sim:/memory_tb/memwrite
    add wave -position end sim:/memory_tb/writedata
    add wave -position end sim:/memory_tb/waitrequest
}

vlib work

;# Compile components
vcom cache/memory.vhd
vcom cache/memory_tb.vhd

;# Start simulation
vsim -t ps memory_tb

# Initialize memory
mem load -filldata FFFFFFFF -fillradix hex /memory_tb/dut/ram_block

;# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run
run 50ns
