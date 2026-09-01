# NanoV RV32E one-tile experiment for Tiny Tapeout SKY130

This project derives from the signed 1x2 NanoV SKY130 port and attempts to fit
the same 16-register RV32E execution architecture into one `1x1` Tiny Tapeout
digital tile. The signed reference project remains unchanged at
`D:/riscv/nanov-tinytapeout-sky`.

The one-tile candidate retains:

- NanoV's bit-serial base-integer CPU and all 16 RV32E architectural registers;
- external SPI instruction and data memory;
- eight combinational GPIO inputs and one eight-bit GPIO output register; and
- the original 12 MHz interface clock.

It removes the UART receiver/transmitter and NanoV's optional multiplier. The
multiplier implements an extension outside base RV32E, and UART is a peripheral,
so neither reduction removes an RV32E architectural register or base-integer
datapath operation. See [the architecture contract](docs/ARCHITECTURE.md).

## Status

**Signed off for TTSKY26c.** Physical revision
`aea43d652be6ea42b024105291aadba46a345347` completed the official SKY130
hardening flow in run `33322018202`, with an independent successful rerun in
`33323135770`. The exact 1x1 design passed placement, routing, antenna, Magic
DRC, LVS, power-grid checks, extracted nine-corner setup and hold timing,
gate-level regression, and Tiny Tapeout precheck. The 97-word self-check and
compiler-generated RV32E firmware also pass. See
[the complete signoff record](docs/SIGNOFF.md) for immutable artifact identities,
physical metrics, and the remaining claim boundaries.

Generate and run the self-checking RTL regression under Ubuntu/WSL:

```sh
cd test
python3 make_test_mem.py test.mem
make clean
make
! grep failure results.xml
```

The 97-word program writes `0x01` after boot, exercises representative RV32E
ALU, shift, comparison, branch, jump, SPI-memory load/store, and GPIO-input
operations, then writes `0xA5`. Any failed comparison writes `0xEE`.

## Provenance and license

The base RTL is Michael Bell's silicon-proven NanoV project from Tiny Tapeout
4. Exact pinned upstream revisions are recorded in [UPSTREAM.md](UPSTREAM.md).
The core and wrapper are Apache-2.0. Retained UART sources remain in the source
tree for provenance but are not listed as design sources or synthesized.
