# Verification status

This is an experimental 1x1 derivative. It has no GDS signoff, gate-level
result, precheck result, shuttle order, or fabricated silicon claim.

## Current evidence

- The source manifest declares `1x1` and excludes UART and multiplier sources.
- The machine-checkable architecture contract passes with `NUM_REGS=16`.
- The self-checking SPI image generator emits 97 RV32E regression words.
- Instruction images now use conventional RV32 little-endian words; the RTL
  corrects the serial receiver's internal bit order without added cells.
- RTL simulation passed under Icarus Verilog 13.0 and Cocotb 2.0.1. The
  97-word self-checking program reached `0xA5` after 331,585.986 ns with one
  test passed and zero failures/errors. A clean rerun generated an FST waveform
  and completed without warnings. The first compile had exposed inherited
  declaration-after-use constructs; declarations were moved before use without
  changing logic before this successful run.
- Generic Yosys synthesis reports 1,725 cells, down from 2,087 cells for the
  signed 1x2 source baseline (362 cells, or 17.3%). This comparison proves a
  real reduction but does not substitute for SKY130 placement and routing.
- GCC 12.3 compiled a freestanding 48-word RV32E/ILP32E firmware image. It
  passed RTL simulation and reached `0xA5` after exercising GPIO and external
  SPI-memory load/store. Prebuilt ELF, binary, memory image, and disassembly are
  provided under `firmware/prebuilt/`.
- Official GDS trial `33312477537` measured 21,577.910 um^2 of movable standard
  cells in a 16,493.318 um^2 core: 135.548% utilization. This proves the first
  derivative does not yet fit one tile and requires substantial RTL area work.
- The selected external-register architecture retains x0-x15 semantics while
  moving writable words to reserved SPI RAM. The fully flattened register/SPI
  subsystem passes real modeled transactions and uses 132 state cells and 411
  total generic cells versus 419 and 655 for the internal register file.
- The parameterized original NanoV core executes `ADDI`, dependent `ADD`, and
  `SUB` through that subsystem, with persistent x5/x6/x7 results. The original
  internal path still passes both full regressions. Instruction fetch,
  multi-cycle execution, load/store, PC, and GPIO integration remain pending,
  so this is not yet a top-level area or signoff claim.

## Required before any tapeout claim

1. RTL program reaches `0xA5` and never reaches `0xEE`.
2. Synthesis proves the reduced netlist fits the one-tile cell-area budget.
3. Official 1x1 placement, CTS, routing, extraction, and multi-corner timing pass.
4. DRC, LVS, antenna, Tiny Tapeout precheck, and extracted gate-level test pass.
5. An immutable source commit is bound to all artifacts and independently audited.
