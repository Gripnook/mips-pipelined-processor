proc AddWaves {} {
    ;#Add waves we're interested in to the Wave window
    add wave -position end sim:/hazard_detector_tb/if_id
    add wave -position end sim:/hazard_detector_tb/id_ex
    add wave -position end sim:/hazard_detector_tb/ex_mem
    add wave -position end sim:/hazard_detector_tb/mem_wb
    add wave -position end sim:/hazard_detector_tb/stall
}

vlib work

;# Compile components
vcom -2008 hazard_detector.vhd
vcom -2008 hazard_detector_tb.vhd

;# Start simulation
vsim -t ps hazard_detector_tb

;# Generate a clock with 1 ns period
#force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run
run 10us
