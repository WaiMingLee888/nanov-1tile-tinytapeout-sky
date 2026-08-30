#!/usr/bin/env bash
set -eu

iverilog -g2012 -s external_register_tb -o /tmp/nanov_extreg.vvp \
    src/nanoV/register_external.v test/external_register_tb.v
vvp /tmp/nanov_extreg.vvp

iverilog -g2012 -s register_spi_tb -o /tmp/nanov_regspi.vvp \
    src/nanoV/register_spi.v test/sim_spi_ram.v test/register_spi_tb.v
vvp /tmp/nanov_regspi.vvp

iverilog -g2012 -s register_subsystem_tb -o /tmp/nanov_regsub.vvp \
    src/nanoV/register_external.v src/nanoV/register_spi.v \
    src/nanoV/register_subsystem.v test/sim_spi_ram.v \
    test/register_subsystem_tb.v
vvp /tmp/nanov_regsub.vvp

iverilog -g2012 -s external_core_harness_tb -o /tmp/nanov_extcore.vvp \
    src/nanoV/alu.v src/nanoV/shift.v src/nanoV/register.v \
    src/nanoV/core.v src/nanoV/register_external.v \
    src/nanoV/register_spi.v src/nanoV/register_subsystem.v \
    src/nanoV/external_core_harness.v test/sim_spi_ram.v \
    test/external_core_harness_tb.v
vvp /tmp/nanov_extcore.vvp

iverilog -g2012 -s external_cpu_tb -o /tmp/nanov_extcpu.vvp \
    src/nanoV/alu.v src/nanoV/shift.v src/nanoV/register.v \
    src/nanoV/core.v src/nanoV/register_sources.v \
    src/nanoV/register_spi.v src/nanoV/cpu_external.v \
    test/sim_spi_ram.v test/external_cpu_tb.v
vvp /tmp/nanov_extcpu.vvp

yosys -q -l /tmp/nanov_extreg_synth.log -s scripts/synth_external_registers.ys
yosys -q -l /tmp/nanov_regspi_synth.log -s scripts/synth_register_spi.ys
yosys -q -l /tmp/nanov_regsub_synth.log -s scripts/synth_register_subsystem.ys
yosys -q -l /tmp/nanov_extcore_synth.log -s scripts/synth_external_core_harness.ys
yosys -q -l /tmp/nanov_extcpu_synth.log -s scripts/synth_external_cpu.ys

echo "All NanoV external-register tests and generic synthesis checks passed."
