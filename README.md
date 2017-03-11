# MIPS Pipelined Processor

This project implements a MIPS processor using a basic 5-stage pipeline comprised of the IF (Instruction Fetch), ID (Instruction Decode), EX (Execute), MEM (Memory Access), and WB (Write Back) stages. The various components are described here.

## Pipeline Registers, Stalls and Flushes

The pipeline registers between each stage were equipped with an enable input and a synchronous, enabled reset. The PC register was also equipped with an enable input. This allows for a simple implementation of stalls and flushes. For example, a stall in ID is implemented by disabling the PC and IF/ID pipeline registers, and resetting the ID/EX pipeline register. This inserts a no-op into the EX stage in the next cycle and freezes the contents of IF and ID. When multiple stalls are required concurrently (for example when a data hazard is detected at the same time as a cache miss), this design gives priority to the later stall in the pipeline. It does so through the enabled reset input. If a pipeline register is disabled, asserting the enabled reset signal does nothing, preventing a stall in ID from wiping the instruction in EX when we are also stalling in MEM.

## Branch Resolution

Branch resolution is implemented in the ID stage. A simple predict not-taken architecture is used, where the next PC is fetched in IF even if a branch is resolving in ID. If we take the branch, the IF/ID register is flushed on the next clock cycle, preserving program integrity.

## Data Hazard Detection

Data hazard detection is implemented through the use of an instruction decoding procedure. This procedure identifies two inputs and one output for each instruction, assigning the register $0 if one of these parameters is unused. A simple combinational block then checks if the inputs in ID match the outputs in EX, MEM, or WB, and stalls the processor accordingly. The register $0 is ignored in checking for data hazards.

## Memory Accesses

Memory accesses occur on the falling edge of the clock in order to allow them to occur between pipeline stages. For data memory accesses, the waitrequest signal is used to stall the pipeline in the MEM stage until the access completes. For instruction memory accesses, the pipeline is stalled in the ID stage. The reason we are not stalling in IF is that branch hazards can occur at the same time as an instruction memory stall. If we were stalling in IF, the branch resolution would flush the IF/ID pipeline register and attempt to branch, but the IF stall would prevent the PC from being updated. Hence we would lose a branch. To prevent this, the ID stage is stalled as well.

## Optimizations
Coming soon...
