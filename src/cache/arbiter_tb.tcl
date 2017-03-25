proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/arbiter_tb/clock
    add wave -position end sim:/arbiter_tb/reset
    add wave -position end sim:/arbiter_tb/i_addr
    add wave -position end sim:/arbiter_tb/i_read
    add wave -position end sim:/arbiter_tb/i_readdata
    add wave -position end sim:/arbiter_tb/i_write
    add wave -position end sim:/arbiter_tb/i_writedata
    add wave -position end sim:/arbiter_tb/i_waitrequest
    add wave -position end sim:/arbiter_tb/d_addr
    add wave -position end sim:/arbiter_tb/d_read
    add wave -position end sim:/arbiter_tb/d_readdata
    add wave -position end sim:/arbiter_tb/d_write
    add wave -position end sim:/arbiter_tb/d_writedata
    add wave -position end sim:/arbiter_tb/d_waitrequest
    add wave -position end sim:/arbiter_tb/m_addr
    add wave -position end sim:/arbiter_tb/m_read
    add wave -position end sim:/arbiter_tb/m_readdata
    add wave -position end sim:/arbiter_tb/m_write
    add wave -position end sim:/arbiter_tb/m_writedata
    add wave -position end sim:/arbiter_tb/m_waitrequest
    add wave -position end sim:/arbiter_tb/dut/state
}

vlib work

;# Compile components
vcom -2008 cache/memory.vhd
vcom -2008 cache/arbiter.vhd
vcom -2008 cache/arbiter_tb.vhd

;# Start simulation
vsim -t ps arbiter_tb

# Initialize memory
mem load -filldata FFFFFFFF -fillradix hex /arbiter_tb/mem/ram_block

;# Add the waves
AddWaves

;# Run
run 250ns
