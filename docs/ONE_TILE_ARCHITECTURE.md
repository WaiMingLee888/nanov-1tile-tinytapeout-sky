# One-tile architecture

## Measured constraint

Official GDS trial `33312477537` reported 21,577.910 um^2 of movable cells in
a 16,493.318 um^2 core, or 135.548% utilization. The mapped netlist contained
579 `sky130_fd_sc_hd__dfxtp_2` cells. At 21.27 um^2 each, sequential cells alone
occupied 12,315.562 um^2.

The internal NanoV register file accounts for 419 generic flip-flops. It stores
13 writable 32-bit registers; x0 is zero and x3/x4 are hardwired ABI constants.
Changing placement density or selecting a slightly smaller drive strength
cannot remove the approximately 9,000 um^2 needed for a routable one-tile
implementation.

## Selected reduction

The existing external SPI RAM will also hold the architectural register words.
This retains the full x0-x15 RV32E register namespace:

- x0 remains hardwired to zero.
- x3 remains `0x00001000` and x4 remains `0x10000000`, matching signed NanoV.
- x1, x2, and x5-x15 occupy reserved SPI-RAM register slots.
- Two source staging rings feed NanoV's unchanged one-bit ALU interface.
- One writeback ring collects the destination result before its SPI write.

The provisional reserved range is the final 64 bytes of the 24-bit SPI address
space, `0xffffc0` through `0xffffff`, with register xN at
`0xffffc0 + 4*N`. Program execution remains confined to NanoV's low 4 MiB PC
range. The register region is private implementation state and may use an
opaque serial layout; ordinary program and data images remain conventional
little-endian bytes.

## Proven external-register path

`nanoV_external_registers` has the same bit-serial operand, destination, SLT
boundary-write, x0, x3, and x4 behavior needed by `nanoV_core`. The SPI engine
performs consecutive standard `02h` writes and `03h` reads against the actual
NanoV simulation RAM. The flattened subsystem directly captures serial operand
bits, normalizes byte bit order, holds ring orientation during transactions,
and writes persistent destination words.

All standalone tests pass. Generic Yosys synthesis reports:

| Implementation | State cells | Total generic cells |
| --- | ---: | ---: |
| Current internal register file | 419 | 655 |
| Serial-capable staging block | 99 | 295 |
| SPI engine with optional word-read output | 48 | 176 |
| Flattened staging + SPI subsystem | 132 | 411 |
| Register-file replacement reduction | 287 | 244 |

The optional SPI word-read buffer is optimized away in the flattened subsystem
because operand rings consume the serial stream directly. Evidence SHA-256
values are:

| Artifact | SHA-256 |
| --- | --- |
| `docs/EXTREG_SYNTH.log` | `204706ece39f2998fdab71d969a1c32dcad8303d9600856b4c38c2cde13c0cc5` |
| `docs/REGSPI_SYNTH.log` | `e4142a8abb2183570d267333075e951528ebaf6f82b6cf849d0e7c48df020d3a` |
| `docs/REGSUB_SYNTH.log` | `b88b8bf40d7d82b21e3b5b2b9845209514d6d4a03b457930c87ed771913829d7` |
| `docs/EXTCORE_SYNTH.log` | `eebb10fecc776600440280b6be758db821147feac944a3185616573f535c1cf3` |

At the mapped `dfxtp_2` area, 287 removed state cells correspond to 6,104.49
um^2. Applying only this sequential saving to the failed placement result gives
a provisional 93.8% movable utilization. The subsystem also has 244 fewer
generic cells overall, but generic counts cannot predict mapped combinational
area. This is a directional estimate, not signoff; only the complete official
SKY130 flow can establish routability.

`nanoV_core` now has a parameterized external bit-serial register interface.
The signed-compatible internal path still passes both the 97-word handwritten
regression and 48-word GCC firmware. An external-core harness executes real
RV32E `ADDI`, dependent `ADD`, and `SUB` instructions and verifies persistent
x5, x6, and x7 SPI-register results. The flattened harness is 770 generic cells
with 217 state cells; it does not yet include instruction fetch, load/store, PC,
GPIO, or the final CPU arbitration FSM.

## Integration sequence

1. Replace the one-cycle harness with a CPU FSM that fetches instructions,
   loads both operands, runs all required NanoV core cycles, and commits rd.
2. Preserve existing load/store SPI transactions, PC changes, and GPIO paths.
3. Extend regression coverage to shifts, branches, jumps, loads, stores, and
   back-to-back dependencies on the external-register top.
4. Run the compiler firmware on that top and obtain a new official mapped-area
   result before further optimization.

If three rings plus the new sequencer still exceed routable density, the next
bounded optimization is to reuse `nanoV_core.stored_data` for writeback or to
stream the second operand during execution. Reducing the architectural register
count is not an acceptable fallback because the objective requires RV32E.
