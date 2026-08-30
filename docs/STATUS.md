# Verification status

This is an experimental 1x1 derivative. It has not yet passed physical-design
or tapeout signoff, so no GDS-ready or fabricated-silicon claim is made.

## Current evidence

- The manifest declares `1x1`, retains RV32E x0-x15, and excludes the optional
  multiplier and UART.
- Writable x1, x2, and x5-x15 words live in reserved SPI RAM locations;
  hardwired x0, x3, and x4 retain signed NanoV semantics. Two rotating source
  rings are reused in place for destination writeback, avoiding a third ring.
- Program/data images and SPI transactions use conventional little-endian byte
  ordering. No firmware-side bit reversal is required.
- The full Tiny Tapeout wrapper passes the 97-word self-checking RV32E
  regression through modeled SPI RAM and GPIO. It covers ALU, shifts,
  comparisons, branches, JAL/JALR, byte/half/word loads and stores, and reaches
  `0xA5` without the `0xEE` failure signature.
- A separate fetched-code directed regression validates dependent operations,
  taken/not-taken branches, jumps and links, SLL/SRL/SRA, SLT/SLTU/SLTI,
  signed/unsigned LB/LH, SB/SH/SW, reserved-register persistence, and GPIO.
- GCC 12.3 builds 48 conventional RV32E/ILP32E words from C. That firmware
  passes on the same external-register top, including general-register-based
  GPIO addressing and SPI scratch-memory checks.
- Mapping the complete wrapper with the retained official SKY130 liberty file
  produces 1,318 standard cells, 197 `dfxtp_2` cells, and 14,652.8032 um^2
  total cell area. Sequential area is 4,190.2688 um^2. Evidence is in
  `ONE_TILE_SKY130_MAP.log` (SHA-256
  `b9e7ade029630c47eaa6b985acc2af743d836f4c7790a0bb77c809587c947b3c`).
- The earlier internal-register GDS trial `33312477537` failed at 21,577.910
  um^2 movable area and 135.548% utilization. The current mapped candidate is
  materially smaller, but mapping is not proof that 92%-target placement and
  routing will succeed.

## Required before any tapeout claim

1. Official 1x1 placement, CTS, routing, extraction, and multi-corner timing pass.
2. DRC, LVS, antenna, Tiny Tapeout precheck, and extracted gate-level test pass.
3. An immutable source commit is bound to all artifacts and independently audited.
