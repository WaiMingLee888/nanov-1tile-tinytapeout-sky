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

## Proven staging result

`nanoV_external_registers` has the same bit-serial operand, destination, SLT
boundary-write, x0, x3, and x4 behavior needed by `nanoV_core`. Its standalone
self-check passes. Generic Yosys synthesis reports:

| Implementation | State cells | Total generic cells |
| --- | ---: | ---: |
| Current internal register file | 419 | 655 |
| External-register staging block | 99 | 220 |
| Reduction before SPI sequencing | 320 | 435 |

The corresponding `docs/EXTREG_SYNTH.log` SHA-256 is
`32bcee7865c933120b1e59265741c39b52197e6a1e5c96f8cc28839dd886fe1c`.

At the mapped `dfxtp_2` area, 320 removed state cells correspond to 6,806.4
um^2. This is a directional estimate, not signoff: the shared SPI transaction
sequencer will add logic, clock buffering will change, and only the official
SKY130 flow can establish final utilization.

## Integration sequence

1. Extend the SPI controller with private register-read and register-write
   phases while retaining commands `03h` and `02h`.
2. Load rs1 and rs2 staging rings before each instruction execution.
3. Execute the existing `nanoV_core` cycles without changing RV32E decode or
   ALU behavior.
4. Write the destination ring to its reserved slot when rd is writable.
5. Resume instruction fetch and preserve the existing load/store and GPIO
   paths.
6. Run the 97-word regression and compiler firmware, then obtain a new
   official mapped-area result before further optimization.

If three rings plus the new sequencer still exceed routable density, the next
bounded optimization is to reuse `nanoV_core.stored_data` for writeback or to
stream the second operand during execution. Reducing the architectural register
count is not an acceptable fallback because the objective requires RV32E.
