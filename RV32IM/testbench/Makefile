## Constantes
SIM_TIME ?= 500
.PHONY: run
run:
	xrun -v200x -f filelist.txt -top RISC_V_pipeline_tb -access +rwc -gui

.PHONY: clean
clean:
	xrun -clean

.PHONY: run-ghdl
run-ghdl:
	rm -f *.cf *.ghw
	ghdl -a --std=08 ../rtl/Util_package.vhd
	ghdl -a --std=08 ../rtl/RISC_V_package.vhd
	ghdl -a --std=08 ../rtl/ALU.vhd
	ghdl -a --std=08 ../rtl/RegisterNbits.vhd
	ghdl -a --std=08 ../rtl/Branch_predictor.vhd
	ghdl -a --std=08 ../rtl/ControlPath.vhd
	ghdl -a --std=08 ../rtl/MUX_ALU.vhd
	ghdl -a --std=08 ../rtl/MUX_LOAD.vhd
	ghdl -a --std=08 ../rtl/MUX_STORE.vhd
	ghdl -a --std=08 ../rtl/NEW_PC.vhd
	ghdl -a --std=08 ../rtl/RegisterFile.vhd
	ghdl -a --std=08 ../rtl/DataPath.vhd
	ghdl -a --std=08 ../rtl/EX_MEM_register.vhd
	ghdl -a --std=08 ../rtl/Forward_unit.vhd
	ghdl -a --std=08 ../rtl/Hazard_Unit.vhd
	ghdl -a --std=08 ../rtl/ID_EX_register.vhd
	ghdl -a --std=08 ../rtl/IF_ID_register.vhd
	ghdl -a --std=08 ../rtl/MEM_WB_register.vhd
	ghdl -a --std=08 ../rtl/MUL_DIV_UNIT.vhd
	ghdl -a --std=08 ../rtl/MUL_DIV_UNIT_tb.vhd
	ghdl -a --std=08 ../rtl/Memory.vhd
	ghdl -a --std=08 ../rtl/Stall_unit.vhd
	ghdl -a --std=08 ../rtl/RISC_V_pipeline_top.vhd
	ghdl -a --std=08 RISC_V_pipeline_tb.vhd
	ghdl -e --std=08 RISC_V_pipeline_tb
	ghdl -r --std=08 RISC_V_pipeline_tb --wave=waveform.ghw --stop-time=$(SIM_TIME)ns  --assert-level=error

.PHONY: gtk
gtk:
	gtkwave waveform.ghw