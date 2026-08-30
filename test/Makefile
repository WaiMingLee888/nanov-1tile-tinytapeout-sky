# Cocotb regression for the NanoV Tiny Tapeout integration.

SIM ?= icarus
FST ?= -fst
TOPLEVEL_LANG ?= verilog
PROG_FILE ?= test.mem
PROG_WORDS ?= 97

SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = \
	tt_top.v \
	nanoV/alu.v \
	nanoV/core.v \
	nanoV/cpu_external.v \
	nanoV/register_sources.v \
	nanoV/register_spi.v \
	nanoV/register.v \
	nanoV/shift.v

COMPILE_ARGS += -DPROG_FILE=\"$(PROG_FILE)\"
COMPILE_ARGS += -DPROG_WORDS=$(PROG_WORDS)
COMPILE_ARGS += -I$(SRC_DIR)
COMPILE_ARGS += -DCOCOTB_SIM

ifneq ($(GATES),yes)

SIM_BUILD = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

SIM_BUILD = sim_build/gl
COMPILE_ARGS += -DGL_TEST
COMPILE_ARGS += -DFUNCTIONAL
COMPILE_ARGS += -DSIM
COMPILE_ARGS += -DUSE_POWER_PINS
COMPILE_ARGS += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

VERILOG_SOURCES += $(PWD)/sim_spi_ram.v
VERILOG_SOURCES += $(PWD)/tb.v

TOPLEVEL = tb
COCOTB_TEST_MODULES = test

include $(shell cocotb-config --makefiles)/Makefile.sim
