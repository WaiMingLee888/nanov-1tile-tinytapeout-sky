# Verification status

This is an experimental 1x1 derivative. It has no GDS signoff, gate-level
result, precheck result, shuttle order, or fabricated silicon claim.

## Current evidence

- The source manifest declares `1x1` and excludes UART and multiplier sources.
- The machine-checkable architecture contract passes with `NUM_REGS=16`.
- The self-checking SPI image generator emits 97 RV32E regression words.
- RTL simulation passed under Icarus Verilog 13.0 and Cocotb 2.0.1. The
  97-word self-checking program reached `0xA5` after 331,585.986 ns with one
  test passed and zero failures/errors. A clean rerun generated an FST waveform
  and completed without warnings. The first compile had exposed inherited
  declaration-after-use constructs; declarations were moved before use without
  changing logic before this successful run.
- Generic Yosys synthesis reports 1,728 cells, down from 2,087 cells for the
  signed 1x2 source baseline (359 cells, or 17.2%). This comparison proves a
  real reduction but does not substitute for SKY130 placement and routing.

## Required before any tapeout claim

1. RTL program reaches `0xA5` and never reaches `0xEE`.
2. Synthesis proves the reduced netlist fits the one-tile cell-area budget.
3. Official 1x1 placement, CTS, routing, extraction, and multi-corner timing pass.
4. DRC, LVS, antenna, Tiny Tapeout precheck, and extracted gate-level test pass.
5. An immutable source commit is bound to all artifacts and independently audited.
