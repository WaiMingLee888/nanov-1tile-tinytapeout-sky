# One-tile architecture contract

## Required invariants

The area experiment may not claim success unless all of these remain true:

1. `NUM_REGS` remains 16; software-visible registers are `x0` through `x15`.
2. The existing NanoV base-integer ALU, immediate, shift, comparison, branch,
   JAL, JALR, load, and store paths remain present.
3. Instructions and ordinary data remain accessible through external SPI
   memory, so useful programs are not limited to an on-chip test ROM.
4. `x3` and `x4` retain NanoV's documented hardwired values (`0x00001000` and
   `0x10000000`) for data-memory and MMIO addressing compatibility.
5. A self-checking program must execute on RTL and the extracted gate-level
   netlist and reach GPIO success signature `0xA5` without reaching `0xEE`.
6. Full physical signoff must pass in the declared 1x1 footprint. Synthesis or
   placement success alone is insufficient.

## Deliberate reductions

| Block | One-tile decision | RV32E effect |
| --- | --- | --- |
| 16-register NanoV CPU | Retained | Required |
| SPI instruction/data memory | Retained | Required for useful execution |
| Eight GPIO inputs | Retained, combinational | None; peripheral |
| Eight GPIO outputs | Retained as one 8-bit register | None; peripheral |
| UART RX/TX | Removed from synthesis | None; peripheral |
| NanoV multiplier | Removed from synthesis | None; M is not part of base RV32E |

The inherited NanoV architecture does not implement traps, interrupts, ECALL,
or EBREAK. This experiment preserves NanoV's existing documented RV32E
capability; it does not upgrade the core into a fully privileged or
spec-compliance-certified processor.

## Pin use

- `ui[7:0]`: eight GPIO inputs.
- `uo[7:0]`: eight GPIO outputs.
- `uio[0]`: SPI MOSI.
- `uio[1]`: active-low SPI chip select.
- `uio[2]`: SPI clock.
- `uio[3]`: SPI MISO.
- `uio[7]`: SPI HOLD behavior inherited from NanoV.
- `uio[6:4]`: unused.
