proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/arbiter_tb/clock
    add wave -position end sim:/arbiter_tb/reset
    add wave -position end sim:/arbiter_tb/i_read
    add wave -position end sim:/arbiter_tb/i_write
    add wave -position end sim:/arbiter_tb/i_wait_request
    add wave -position end sim:/arbiter_tb/d_read
    add wave -position end sim:/arbiter_tb/d_write
    add wave -position end sim:/arbiter_tb/d_wait_request
    add wave -position end sim:/arbiter_tb/mem_read
    add wave -position end sim:/arbiter_tb/mem_write
    add wave -position end sim:/arbiter_tb/mem_wait_request
    add wave -position end sim:/arbiter_tb/i_readdata
    add wave -position end sim:/arbiter_tb/i_writedata
    add wave -position end sim:/arbiter_tb/i_adr
    add wave -position end sim:/arbiter_tb/d_readdata
    add wave -position end sim:/arbiter_tb/d_writedata
    add wave -position end sim:/arbiter_tb/d_adr
    add wave -position end sim:/arbiter_tb/mem_readdata
    add wave -position end sim:/arbiter_tb/mem_writedata
    add wave -position end sim:/arbiter_tb/mem_adr
}

vlib work

;# Compile components
vcom cache/arbiter.vhd
vcom -2008 cache/arbiter_tb.vhd

;# Start simulation
vsim -t ps arbiter_tb

;# Add the waves
AddWaves

;# Run
run 40ns
