# MIPS Pipelined Processor

A MIPS processor implemented using a basic 5-stage pipeline comprised of the IF (Instruction Fetch), ID (Instruction Decode), EX (Execute), MEM (Memory Access), and WB (Write Back) stages. It was optimized through the use of data forwarding, caching and branch prediction. See the [report](report/final-report/final-report.pdf) for more details.

The processor can execute programs written using a subset of the MIPS instruction set, as described in [one of the specifications](specs/W17ECSE425P4PipelinedProcessor.pdf). One additional restriction is that the program must end in an infinite loop which uses the BEQ instruction. This is required for the processor to be able to detect program termination and clear the contents of the caches.

To execute an assembly program, it must first be assembled to machine code and stored as a binary text file named 'program.txt'. An assembler is provided in the [assembler/](assembler/) directory. Then, it must be moved to the [src/](src/) directory and the following command must be executed in the ModelSim command line:

```
source testbench.tcl
```

This script outputs the contents of the register file and of main memory to text files in the same directory. Several assembly programs are provided in the [src/test-programs/](src/test-programs/) directory.

In addition, the whole suite of test programs can be run by executing the following command in the ModelSim command line:

```
source benchmarks.tcl
```

This script runs all the programs in the [src/test-programs/](src/test-programs/) directory and compares the outputs to expected results stored in the same directory. It also outputs the contents of internal performance counters to the ModelSim command line for performance analysis. Note that this script uses the 'diff' program to compare files. If this program is not present on the system path, the performance counters will still be displayed but the script will not be able to check for test program correctness.
