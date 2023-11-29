# FPGA Implementation
XTCL scripts are provided to setup the project, compile and burn to configuration flash.

## Execution

    vivado -mode batch -source setup.tcl
    vivado -mode batch -source compile.tcl
    vivado -mode batch -source spi_program.tcl


