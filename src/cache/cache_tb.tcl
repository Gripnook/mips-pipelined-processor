proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/cache_tb/clock
    add wave -position end sim:/cache_tb/reset
    add wave -position end sim:/cache_tb/s_addr
    add wave -position end sim:/cache_tb/s_read
    add wave -position end sim:/cache_tb/s_readdata
    add wave -position end sim:/cache_tb/s_write
    add wave -position end sim:/cache_tb/s_writedata
    add wave -position end sim:/cache_tb/s_waitrequest
    add wave -position end sim:/cache_tb/m_addr
    add wave -position end sim:/cache_tb/m_read
    add wave -position end sim:/cache_tb/m_readdata
    add wave -position end sim:/cache_tb/m_write
    add wave -position end sim:/cache_tb/m_writedata
    add wave -position end sim:/cache_tb/m_waitrequest
    
    add wave -position end sim:/cache_tb/dut/controller/state
    
    add wave -position end sim:/cache_tb/dut/cache_memory/read_en
    add wave -position end sim:/cache_tb/dut/cache_memory/data_out
    add wave -position end sim:/cache_tb/dut/cache_memory/write_en
    add wave -position end sim:/cache_tb/dut/cache_memory/data_in
    add wave -position end sim:/cache_tb/dut/cache_memory/dirty_clr
    add wave -position end sim:/cache_tb/dut/cache_memory/tag_in
    add wave -position end sim:/cache_tb/dut/cache_memory/block_index_in
    add wave -position end sim:/cache_tb/dut/cache_memory/block_offset_in
}

vlib work

;# Compile components
vcom cache/memory.vhd
vcom cache/cache_controller.vhd
vcom cache/cache_block.vhd
vcom cache/cache.vhd
vcom cache/cache_tb.vhd

;# Start simulation
vsim -t ps cache_tb

# Initialize memory
mem load -filldata FFFFFFFF -fillradix hex /cache_tb/mem/ram_block

;# Generate a clock with 1 ns period
force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run
run 10us
